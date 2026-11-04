import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/epg_program_model.dart';
import '../../data/repositories/channel_repository.dart';

class PlayerController extends GetxController {
  final ChannelRepository _channelRepo = Get.find<ChannelRepository>();

  late ChannelModel currentChannel;
  late List<ChannelModel> channelList;

  VideoPlayerController? videoPlayerController;
  final RxBool isPlayerInitialized = false.obs;
  final RxBool isBuffering = true.obs;
  final RxBool isPlaying = false.obs;
  final RxString streamError = ''.obs;

  // EPG
  final Rxn<EpgProgramModel> currentProgram = Rxn<EpgProgramModel>();

  // TV OSD (On-Screen Display) Controls
  final RxBool showOsd = true.obs;
  final RxBool showQuickGuide = false.obs;
  final RxString selectedQuality = 'Auto (1080p)'.obs;

  Timer? _osdTimer;

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

      final uri = Uri.parse(playbackInfo.streamUrl);
      videoPlayerController = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: playbackInfo.headers,
      );

      await videoPlayerController!.initialize();
      videoPlayerController!.addListener(_videoListener);
      await videoPlayerController!.play();

      isPlayerInitialized.value = true;
      isPlaying.value = true;
      isBuffering.value = false;
    } catch (e) {
      streamError.value = 'Unable to establish stream connection. Retrying...';
      isBuffering.value = false;
    }
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

