import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../core/services/quality_bridge.dart';
import '../../core/storage/hive_service.dart';
import '../../data/models/audio_track_option.dart';
import '../../data/models/category_model.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/epg_program_model.dart';
import '../../data/models/quality_option.dart';
import '../../data/repositories/channel_repository.dart';
import '../../routes/app_routes.dart';
import '../home/home_controller.dart';
import 'package:flutter/material.dart' show Icons;
import 'widgets/audio_language_dialog.dart';

class PlayerController extends GetxController {
  final ChannelRepository _channelRepo = Get.find<ChannelRepository>();

  ChannelModel currentChannel = ChannelModel.fallback;
  List<ChannelModel> channelList = const [];

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
  final RxBool showBottomChannelTray = false.obs;
  final RxBool showQualityMenu = false.obs;
  final RxString settingsSubMenu = ''.obs; // '' for main, 'quality' for quality, 'speed' for speed
  final Rx<QualityOption> selectedQualityOption = QualityOption.defaultOptions.first.obs;
  final RxString selectedQuality = 'Auto'.obs;
  final RxList<QualityOption> availableQualityOptions = <QualityOption>[].obs;

  // YouTube Features: Miniplayer & Speed
  final RxBool isMinimized = false.obs;
  final RxDouble playbackSpeed = 1.0.obs;

  // Volume & Playback Controls
  final RxDouble volume = 1.0.obs;
  final RxBool isMuted = false.obs;
  double _previousVolume = 1.0;

  // Seeking, Timeline & Live Delay
  final RxBool isLiveStream = true.obs;
  final Rx<Duration> currentPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;
  final RxBool isLiveEdge = true.obs;
  final RxString liveDelayText = ''.obs;
  int liveOffsetSeconds = 0;

  // Window Controls
  final RxBool isFullscreen = false.obs;

  // Audio Language Selection
  final RxList<AudioTrackOption> availableAudioTracks = <AudioTrackOption>[].obs;
  final RxString selectedAudioLanguage = 'Audio'.obs;

  Timer? _osdTimer;
  Timer? _toastTimer;

  String _baseStreamUrl = '';
  Map<String, String> _playbackHeaders = {};

  DateTime _lastLiveSyncTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _consecutiveBufferTicks = 0;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['preferredQuality'] is QualityOption) {
      selectedQualityOption.value = args['preferredQuality'] as QualityOption;
    } else {
      selectedQualityOption.value = HiveService.getPreferredQualityOption();
    }
    selectedQuality.value = selectedQualityOption.value.id == 'auto'
        ? 'Auto'
        : '${selectedQualityOption.value.targetHeight}p';

    ChannelModel? targetChannel;
    if (args != null && args['channel'] is ChannelModel) {
      targetChannel = args['channel'] as ChannelModel;
      channelList = (args['channelList'] as List<ChannelModel>?) ?? [targetChannel];
      HiveService.saveLastPlayedChannel(targetChannel);
    } else if (Get.currentRoute == AppRoutes.player) {
      // Browser reload or direct link to /player - resume saved channel
      targetChannel = HiveService.getLastPlayedChannel();
      final cached = HiveService.getCachedChannels();
      channelList = cached.isNotEmpty ? cached : (targetChannel != null ? [targetChannel] : []);
    }

    if (targetChannel != null) {
      if (videoPlayerController != null &&
          isPlayerInitialized.value &&
          currentChannel.channelId == targetChannel.channelId) {
        // Stream already running from miniplayer! Un-minimize and keep playing
        isMinimized.value = false;
        _resetOsdTimer();
        return;
      }
      currentChannel = targetChannel;
      _initializeChannel(currentChannel);
      if (channelList.length <= 1) {
        _loadChannelsInBackground();
      }
    }
  }

  Future<void> _loadChannelsInBackground() async {
    try {
      final list = await _channelRepo.getChannels();
      if (list.isNotEmpty) {
        channelList = list;
        HiveService.saveCachedChannels(list);
      }
    } catch (_) {}
  }

  @override
  void onClose() {
    if (!isMinimized.value) {
      _osdTimer?.cancel();
      _toastTimer?.cancel();
      videoPlayerController?.dispose();
    }
    super.onClose();
  }

  void minimizePlayer() {
    isMinimized.value = true;
    showOsd.value = false;
    showQualityMenu.value = false;
    showBottomChannelTray.value = false;
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
    _resumePlaybackLoop();
  }

  void expandPlayer() {
    isMinimized.value = false;
    Get.toNamed(
      AppRoutes.player,
      arguments: {
        'channel': currentChannel,
        'channelList': channelList,
        'preferredQuality': selectedQualityOption.value,
      },
    );
    _resumePlaybackLoop();
  }

  void _resumePlaybackLoop() {
    void attemptPlay() {
      if (videoPlayerController != null) {
        videoPlayerController!.play();
      }
      if (kIsWeb) {
        webResumeVideo();
      }
    }

    attemptPlay();
    WidgetsBinding.instance.addPostFrameCallback((_) => attemptPlay());
    Future.delayed(const Duration(milliseconds: 100), attemptPlay);
    Future.delayed(const Duration(milliseconds: 300), attemptPlay);
    Future.delayed(const Duration(milliseconds: 600), attemptPlay);
    Future.delayed(const Duration(milliseconds: 1000), attemptPlay);
  }

  void closeMiniplayer() {
    isMinimized.value = false;
    videoPlayerController?.pause();
    videoPlayerController?.dispose();
    videoPlayerController = null;
    isPlayerInitialized.value = false;
  }

  void setPlaybackSpeed(double speed) {
    playbackSpeed.value = speed;
    videoPlayerController?.setPlaybackSpeed(speed);
    _showToast('Speed: ${speed == 1.0 ? "Normal" : "${speed}x"}');
  }

  Future<void> _initializeChannel(ChannelModel channel) async {
    currentChannel = channel;
    HiveService.saveLastPlayedChannel(channel);
    isPlayerInitialized.value = false;
    isBuffering.value = true;
    streamError.value = '';
    availableAudioTracks.clear();
    availableQualityOptions.clear();
    selectedAudioLanguage.value = channel.languageName.isNotEmpty ? channel.languageName : 'Audio';

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

      // On Web, sync Hls.js quality level if non-auto was chosen
      if (selectedQualityOption.value.targetHeight > 0) {
        Future.delayed(const Duration(milliseconds: 500), () {
          switchWebQuality(selectedQualityOption.value.targetHeight);
        });
      }

      // Query available audio tracks and dynamic quality options after player attaches
      Future.delayed(const Duration(milliseconds: 1000), () {
        refreshAudioTracks();
        refreshQualityOptions();
      });
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
    return _baseStreamUrl;
  }

  Future<void> changeQuality(QualityOption option) async {
    showQualityMenu.value = false;
    selectedQualityOption.value = option;
    selectedQuality.value = option.id == 'auto' ? 'Auto' : '${option.targetHeight}p';

    if (availableQualityOptions.isNotEmpty) {
      availableQualityOptions.value = availableQualityOptions.map((q) {
        final matches = (option.id == 'auto' && q.id == 'auto') ||
            (option.targetHeight > 0 && q.targetHeight == option.targetHeight) ||
            (option.id == q.id);
        return q.copyWith(isActive: matches);
      }).toList();
    }

    // 1. Attempt instantaneous Hls.js level switch on Web
    final switchedOnWeb = switchWebQuality(option.targetHeight);
    if (switchedOnWeb) {
      _showToast('Resolution: ${option.label}');
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
        _showToast('Resolution: ${option.label}');
      } catch (e) {
        debugPrint('[QUALITY_CHANGE_ERROR] $e');
        isBuffering.value = false;
      }
    }
  }

  void toggleQualityMenu() {
    showQualityMenu.value = !showQualityMenu.value;
    if (showQualityMenu.value) {
      settingsSubMenu.value = '';
      refreshQualityOptions();
      _resetOsdTimer(seconds: 15);
    }
  }

  void closeQualityMenu() {
    showQualityMenu.value = false;
    settingsSubMenu.value = '';
  }

  void openQualitySelector() {
    toggleQualityMenu();
  }

  void refreshQualityOptions() {
    try {
      final rawLevels = getWebQualityLevels();
      if (rawLevels.isNotEmpty) {
        availableQualityOptions.value = rawLevels.map((m) => QualityOption.fromJson(m)).toList();
        final active = availableQualityOptions.firstWhereOrNull((q) => q.isActive);
        if (active != null) {
          selectedQuality.value = active.label;
        }
      }
    } catch (_) {}
  }

  void refreshAudioTracks() {
    try {
      final rawTracks = getWebAudioTracks();
      if (rawTracks.isNotEmpty) {
        availableAudioTracks.value = rawTracks.map((m) => AudioTrackOption.fromJson(m)).toList();
        final active = availableAudioTracks.firstWhereOrNull((t) => t.isActive);
        if (active != null) {
          selectedAudioLanguage.value = active.label;
        } else if (availableAudioTracks.isNotEmpty) {
          selectedAudioLanguage.value = availableAudioTracks.first.label;
        }
      }
    } catch (_) {}
  }

  void changeAudioTrack(AudioTrackOption option) {
    final success = switchWebAudioTrack(option.id.isNotEmpty ? option.id : option.language);
    if (success) {
      selectedAudioLanguage.value = option.label;
      availableAudioTracks.value = availableAudioTracks.map((t) {
        return t.copyWith(isActive: t.id == option.id);
      }).toList();
      _showToast('Audio language: ${option.label}');
    }
  }

  void openAudioSelector() {
    refreshAudioTracks();
    Get.dialog(
      AudioLanguageDialog(
        availableTracks: availableAudioTracks,
        onSelect: (opt) => changeAudioTrack(opt),
      ),
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

    final pos = videoPlayerController!.value.position;
    final dur = videoPlayerController!.value.duration;

    // Detect if stream is a live TV broadcast or standard VOD file
    // All broadcast channels in PrismTV are live streams
    if (dur > const Duration(hours: 12) || dur == Duration.zero || isLiveStream.value) {
      isLiveStream.value = true;
      currentPosition.value = Duration.zero;
      totalDuration.value = Duration.zero;

      // Query real live edge delay from the HLS media engine or relative seek offset
      final webDelay = getWebLiveDelay();
      final effectiveDelay = webDelay > liveOffsetSeconds ? webDelay : liveOffsetSeconds;
      if (effectiveDelay <= 4) {
        isLiveEdge.value = true;
        liveDelayText.value = '';
      } else {
        isLiveEdge.value = false;
        final m = effectiveDelay ~/ 60;
        final s = effectiveDelay % 60;
        liveDelayText.value = '-$m:${s.toString().padLeft(2, '0')}';
      }
    } else {
      isLiveStream.value = false;
      currentPosition.value = pos;
      totalDuration.value = dur;
      isLiveEdge.value = false;
      liveDelayText.value = '';
    }

    // Auto-recover if stuck in buffer stall for > 5 seconds
    if (isBuffering.value && isPlaying.value) {
      _consecutiveBufferTicks++;
      if (_consecutiveBufferTicks >= 10) {
        _consecutiveBufferTicks = 0;
        try {
          videoPlayerController?.play();
        } catch (_) {}
      }
    } else {
      _consecutiveBufferTicks = 0;
    }
  }

  void onUserInteraction() {
    if (!showOsd.value) {
      showOsd.value = true;
    }
    _resetOsdTimer();
  }

  void seekToPosition(Duration pos) {
    if (videoPlayerController == null) return;
    videoPlayerController!.seekTo(pos);
    _resetOsdTimer();
  }

  void seekRelative(int seconds) {
    if (videoPlayerController == null) return;
    if (isLiveStream.value) {
      // Seeking backward increases delay behind live edge
      liveOffsetSeconds = (liveOffsetSeconds - seconds).clamp(0, 7200);
      if (liveOffsetSeconds > 4) {
        isLiveEdge.value = false;
        final m = liveOffsetSeconds ~/ 60;
        final s = liveOffsetSeconds % 60;
        liveDelayText.value = '-$m:${s.toString().padLeft(2, '0')}';
      } else {
        isLiveEdge.value = true;
        liveDelayText.value = '';
      }
    }
    final pos = videoPlayerController!.value.position;
    final dur = videoPlayerController!.value.duration;
    final target = pos + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (dur > Duration.zero && target > dur ? dur : target);
    videoPlayerController!.seekTo(clamped);
    _resetOsdTimer();
  }

  void goToLive() {
    final now = DateTime.now();
    if (now.difference(_lastLiveSyncTime).inMilliseconds < 1000) {
      return;
    }
    _lastLiveSyncTime = now;
    liveOffsetSeconds = 0;
    isLiveEdge.value = true;
    liveDelayText.value = '';

    webGoToLive();
    if (videoPlayerController != null) {
      final dur = videoPlayerController!.value.duration;
      if (dur > Duration.zero && dur < const Duration(hours: 12)) {
        final target = dur > const Duration(seconds: 3) ? dur - const Duration(seconds: 3) : dur;
        videoPlayerController!.seekTo(target);
      }
      if (!videoPlayerController!.value.isPlaying) {
        videoPlayerController!.play();
      }
    }
    _showToast('Synced to Live Stream');
    _resetOsdTimer();
  }

  void setVolume(double val) {
    volume.value = val.clamp(0.0, 1.0);
    isMuted.value = volume.value == 0.0;
    videoPlayerController?.setVolume(volume.value);
    _resetOsdTimer();
  }

  void toggleMute() {
    if (isMuted.value) {
      isMuted.value = false;
      volume.value = _previousVolume > 0.05 ? _previousVolume : 1.0;
    } else {
      _previousVolume = volume.value;
      isMuted.value = true;
      volume.value = 0.0;
    }
    videoPlayerController?.setVolume(volume.value);
    _resetOsdTimer();
  }

  void toggleFullscreen() {
    try {
      toggleWebFullscreen();
      isFullscreen.value = !isFullscreen.value;
    } catch (_) {
      isFullscreen.value = !isFullscreen.value;
    }
    _resetOsdTimer();
  }

  void togglePiP() {
    try {
      toggleWebPiP();
      _showToast('Miniplayer triggered');
    } catch (_) {}
    _resetOsdTimer();
  }

  void toggleBottomChannelTray() {
    showBottomChannelTray.value = !showBottomChannelTray.value;
    if (showBottomChannelTray.value) {
      showQualityMenu.value = false;
      showOsd.value = true;
      _osdTimer?.cancel();
    } else {
      _resetOsdTimer();
    }
  }

  void closeBottomChannelTray() {
    if (showBottomChannelTray.value) {
      showBottomChannelTray.value = false;
      _resetOsdTimer();
    }
  }

  void goBack() {
    if (showQualityMenu.value) {
      closeQualityMenu();
      return;
    }
    if (showBottomChannelTray.value) {
      closeBottomChannelTray();
      return;
    }
    // Clicking back closes the player completely (does not minimize)
    isMinimized.value = false;
    videoPlayerController?.pause();
    videoPlayerController?.dispose();
    videoPlayerController = null;
    isPlayerInitialized.value = false;
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  Future<void> _loadEpg(int channelId) async {
    try {
      final epg = await _channelRepo.getEpg(channelId);
      currentProgram.value = epg.nowPlayingOrUpcoming;
    } catch (_) {
      currentProgram.value = null;
    }
  }

  // ==========================================
  // Categorized Sections Synced with Home Screen Filters
  // ==========================================
  List<MapEntry<CategoryModel, List<ChannelModel>>> get categorizedSections {
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      final sections = home.categorizedSections;
      if (sections.isNotEmpty) return sections;
    }
    // Fallback: organize channelList by category
    final Map<String, List<ChannelModel>> map = {};
    for (final ch in channelList) {
      final cat = ch.categoryName.isNotEmpty ? ch.categoryName : 'General';
      map.putIfAbsent(cat, () => []).add(ch);
    }
    return map.entries.map((e) => MapEntry(
      CategoryModel(id: e.key.toLowerCase(), title: e.key, icon: Icons.tv_rounded),
      e.value,
    )).toList();
  }

  // ==========================================
  // Direct Channel Number Dialing Buffer
  // ==========================================
  Timer? _dialTimer;
  String _dialBuffer = '';

  void _handleNumberKey(int digit) {
    _dialTimer?.cancel();
    _dialBuffer += digit.toString();
    _showToast('Channel $_dialBuffer...');

    _dialTimer = Timer(const Duration(milliseconds: 1400), () {
      final dialNum = int.tryParse(_dialBuffer);
      final dialed = _dialBuffer;
      _dialBuffer = '';
      if (dialNum == null) return;

      // 1. Try matching by channelId
      ChannelModel? target = channelList.firstWhereOrNull((c) => c.channelId == dialNum);

      // 2. Fallback: match by 1-based index
      if (target == null && dialNum > 0 && dialNum <= channelList.length) {
        target = channelList[dialNum - 1];
      }

      if (target != null) {
        switchChannel(target);
        _showToast('Tuned to ${target.channelName}');
      } else {
        _showToast('Channel $dialed not found');
      }
    });
  }

  int? _getDigitFromKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) return 0;
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) return 1;
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) return 2;
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) return 3;
    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) return 4;
    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) return 5;
    if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) return 6;
    if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) return 7;
    if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) return 8;
    if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) return 9;
    return null;
  }

  // ==========================================
  // TV Remote & Keyboard Actions
  // ==========================================
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
    showBottomChannelTray.value = false;
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

  void handleSurfaceTap() {
    if (showQualityMenu.value) {
      closeQualityMenu();
      return;
    }
    if (showBottomChannelTray.value) {
      closeBottomChannelTray();
      return;
    }
    toggleOsd();
  }

  void toggleOsd() {
    showOsd.value = !showOsd.value;
    if (showOsd.value) {
      _resetOsdTimer();
    }
  }

  void _resetOsdTimer({int seconds = 5}) {
    showOsd.value = true;
    _osdTimer?.cancel();
    _osdTimer = Timer(Duration(seconds: seconds), () {
      if (!showQualityMenu.value && !showBottomChannelTray.value) {
        showOsd.value = false;
      }
    });
  }

  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    // 1. Back / Dismiss (TV Remote Back, Escape, Backspace, Android TV goBack)
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.goBack) {
      if (Get.isDialogOpen == true) {
        Get.back();
        return KeyEventResult.handled;
      }
      if (showQualityMenu.value) {
        closeQualityMenu();
        return KeyEventResult.handled;
      }
      if (showBottomChannelTray.value) {
        closeBottomChannelTray();
        return KeyEventResult.handled;
      }
      if (showOsd.value) {
        showOsd.value = false;
        return KeyEventResult.handled;
      }
      // Return to Home Screen
      goBack();
      return KeyEventResult.handled;
    }

    // 2. When Channel Tray or Dialogs are open, let their own focus trees handle arrow navigation
    if (showBottomChannelTray.value || showQualityMenu.value || (Get.isDialogOpen == true)) {
      return KeyEventResult.ignored;
    }

    // 3. Play / Pause (Space, Remote Play/Pause, MediaPlay, MediaPause)
    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause) {
      togglePlayPause();
      _showToast(videoPlayerController?.value.isPlaying == true ? 'Playing' : 'Paused');
      return KeyEventResult.handled;
    }

    // 4. Down Arrow -> Opens Categorized Channels Tray
    if (key == LogicalKeyboardKey.arrowDown) {
      toggleBottomChannelTray();
      return KeyEventResult.handled;
    }

    // 5. Up Arrow -> Shows Show Info & OSD Overlay
    if (key == LogicalKeyboardKey.arrowUp) {
      if (!showOsd.value) {
        showOsd.value = true;
        _resetOsdTimer();
        return KeyEventResult.handled;
      }
    }

    // 6. Left / Right Arrows -> Next / Previous Channel (with feedback toast)
    if (key == LogicalKeyboardKey.arrowLeft) {
      previousChannel();
      _showToast('◄ ${currentChannel.channelName}');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      nextChannel();
      _showToast('► ${currentChannel.channelName}');
      return KeyEventResult.handled;
    }

    // 7. Dedicated Remote Channel Up / Down
    if (key == LogicalKeyboardKey.channelUp) {
      nextChannel();
      _showToast('▲ ${currentChannel.channelName}');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.channelDown) {
      previousChannel();
      _showToast('▼ ${currentChannel.channelName}');
      return KeyEventResult.handled;
    }

    // 8. OK / Enter / Select -> Toggles OSD when playing
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      toggleOsd();
      return KeyEventResult.handled;
    }

    // 9. Numeric Keys (0 - 9) -> Direct channel number dialing
    final digit = _getDigitFromKey(key);
    if (digit != null) {
      _handleNumberKey(digit);
      return KeyEventResult.handled;
    }

    // 10. Shortcut Hotkeys
    if (key == LogicalKeyboardKey.keyC) {
      toggleBottomChannelTray();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyQ) {
      openQualitySelector();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyA) {
      openAudioSelector();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyF) {
      toggleFullscreen();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyM || key == LogicalKeyboardKey.audioVolumeMute) {
      toggleMute();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyO || key == LogicalKeyboardKey.keyS) {
      toggleOsd();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
