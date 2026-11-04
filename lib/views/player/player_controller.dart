import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../core/services/quality_bridge.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/epg_program_model.dart';
import '../../data/models/quality_option.dart';
import '../../data/repositories/channel_repository.dart';
import 'widgets/resolution_dialog.dart';

class PlayerController extends GetxController {
  final ChannelRepository _channelRepo = Get.find<ChannelRepository>();

  late ChannelModel currentChannel;
  late List<ChannelModel> channelList;

  VideoPlayerController? videoPlayerController;
  final RxBool isPlayerInitialized = false.obs;
  final RxBool isBuffering = true.obs;
  final RxBool isPlaying = false.obs;
  final RxString streamError = ''.obs;
  final RxString toastMessage = ''.obs;

  // EPG
  final Rxn<EpgProgramModel> currentProgram = Rxn<EpgProgramModel>();

  // TV OSD Controls & Resolution
  final RxBool showOsd = true.obs;
  final RxBool showQuickGuide = false.obs;
  final Rx<QualityOption> selectedQualityOption = QualityOption.defaultOptions.first.obs;
  final RxString selectedQuality = 'Auto'.obs;

  Timer? _osdTimer;
  Timer? _toastTimer;

  String _baseStreamUrl = '';
  Map<String, String> _playbackHeaders = {};

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      currentChannel = args['channel'] as ChannelModel;
      channelList = (args['channelList'] as List<ChannelModel>?) ?? [currentChannel];
    }
    _initializeChannel(currentChannel);
  }

  @override
  void onClose() {
    _osdTimer?.cancel();
    _toastTimer?.cancel();
    videoPlayerController?.dispose();
    super.onClose();
  }

  Future<void> _initializeChannel(ChannelModel channel) async {
    currentChannel = channel;
    isPlayerInitialized.value = false;
    isBuffering.value = true;
    streamError.value = '';

    _loadEpg(channel.channelId);
    _resetOsdTimer();

    // Dispose previous player
    await videoPlayerController?.dispose();
    videoPlayerController = null;

    try {
      final playbackInfo = await _channelRepo.getStream(channel);
      _baseStreamUrl = playbackInfo.streamUrl;
      _playbackHeaders = playbackInfo.headers;

      final targetUrl = _buildStreamUrlForQuality(selectedQualityOption.value);
      final uri = Uri.parse(targetUrl);
      videoPlayerController = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: _playbackHeaders,
      );

      await videoPlayerController!.initialize();
      videoPlayerController!.addListener(_videoListener);
      await videoPlayerController!.play();

      isPlayerInitialized.value = true;
      isPlaying.value = true;
      isBuffering.value = false;

      // On Web, sync Hls.js quality level if non-auto was previously chosen
      if (selectedQualityOption.value.targetHeight > 0) {
        Future.delayed(const Duration(milliseconds: 600), () {
          switchWebQuality(selectedQualityOption.value.targetHeight);
        });
      }
    } catch (e) {
      debugPrint('[PRISM_PLAYER_ERROR] $e');
      if (e.toString().contains('Authentication') || e.toString().contains('419') || e.toString().contains('401')) {
        streamError.value = 'Session expired. Please log in again from Profile.';
      } else {
        streamError.value = 'Unable to establish stream connection. Retrying...';
      }
      isBuffering.value = false;
    }
  }

  String _buildStreamUrlForQuality(QualityOption quality) {
    if (_baseStreamUrl.isEmpty) return '';
    if (quality.id == 'auto') return _baseStreamUrl;

    // Apply bitrate bounds into stream URL
    var url = _baseStreamUrl;
    if (url.contains('minrate=') && url.contains('maxrate=')) {
      url = url.replaceAll(RegExp(r'minrate=\d+'), 'minrate=${quality.minRate}');
      url = url.replaceAll(RegExp(r'maxrate=\d+'), 'maxrate=${quality.maxRate}');
    } else {
      final sep = url.contains('?') ? '&' : '?';
      url = '$url${sep}minrate=${quality.minRate}&maxrate=${quality.maxRate}';
    }
    return url;
  }

  Future<void> changeQuality(QualityOption option) async {
    selectedQualityOption.value = option;
    selectedQuality.value = option.id == 'auto' ? 'Auto' : '${option.targetHeight}p';

    // 1. Attempt instantaneous Hls.js level switch on Web
    final switchedOnWeb = switchWebQuality(option.targetHeight);
    if (switchedOnWeb) {
      _showToast('Resolution changed to ${option.label}');
      return;
    }

    // 2. Otherwise update stream URL and reload video controller
    if (_baseStreamUrl.isNotEmpty) {
      isBuffering.value = true;
      try {
        final targetUrl = _buildStreamUrlForQuality(option);
        final uri = Uri.parse(targetUrl);

        final oldController = videoPlayerController;
        final newController = VideoPlayerController.networkUrl(
          uri,
          httpHeaders: _playbackHeaders,
        );

        await newController.initialize();
        newController.addListener(_videoListener);
        await newController.play();

        videoPlayerController = newController;
        await oldController?.dispose();

        isBuffering.value = false;
        _showToast('Resolution changed to ${option.label}');
      } catch (e) {
        debugPrint('[QUALITY_CHANGE_ERROR] $e');
        isBuffering.value = false;
      }
    }
  }

  void openQualitySelector() {
    Get.dialog(
      ResolutionDialog(controller: this),
      barrierColor: const Color(0x99000000),
    );
  }

  void _showToast(String message) {
    toastMessage.value = message;
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (toastMessage.value == message) {
        toastMessage.value = '';
      }
    });
  }

  void _videoListener() {
    if (videoPlayerController == null) return;
    isBuffering.value = videoPlayerController!.value.isBuffering;
    isPlaying.value = videoPlayerController!.value.isPlaying;
  }

  Future<void> _loadEpg(int channelId) async {
    try {
      final epg = await _channelRepo.getEpg(channelId);
      if (epg.isNotEmpty) {
        currentProgram.value = epg.firstWhere(
          (p) => p.isNowPlaying,
          orElse: () => epg.first,
        );
      } else {
        currentProgram.value = null;
      }
    } catch (_) {
      currentProgram.value = null;
    }
  }

  // TV Remote Key Actions
  void nextChannel() {
    final index = channelList.indexWhere((c) => c.channelId == currentChannel.channelId);
    if (index != -1 && index + 1 < channelList.length) {
      _initializeChannel(channelList[index + 1]);
    } else if (channelList.isNotEmpty) {
      _initializeChannel(channelList.first);
    }
  }

  void previousChannel() {
    final index = channelList.indexWhere((c) => c.channelId == currentChannel.channelId);
    if (index > 0) {
      _initializeChannel(channelList[index - 1]);
    } else if (channelList.isNotEmpty) {
      _initializeChannel(channelList.last);
    }
  }

  void switchChannel(ChannelModel channel) {
    showQuickGuide.value = false;
    _initializeChannel(channel);
  }

  void togglePlayPause() {
    if (videoPlayerController == null) return;
    if (videoPlayerController!.value.isPlaying) {
      videoPlayerController!.pause();
    } else {
      videoPlayerController!.play();
    }
    _resetOsdTimer();
  }

  void toggleOsd() {
    showOsd.value = !showOsd.value;
    if (showOsd.value) {
      _resetOsdTimer();
    }
  }

  void toggleQuickGuide() {
    showQuickGuide.value = !showQuickGuide.value;
    if (showQuickGuide.value) {
      showOsd.value = false;
    }
  }

  void _resetOsdTimer() {
    showOsd.value = true;
    _osdTimer?.cancel();
    _osdTimer = Timer(const Duration(seconds: 5), () {
      if (!showQuickGuide.value) {
        showOsd.value = false;
      }
    });
  }

  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (!showQuickGuide.value) {
          nextChannel();
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (!showQuickGuide.value) {
          previousChannel();
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        toggleQuickGuide();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyQ) {
        openQualitySelector();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        if (!showQuickGuide.value) {
          toggleOsd();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }
}
