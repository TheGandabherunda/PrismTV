import '../models/channel_model.dart';
import '../models/epg_program_model.dart';

class StreamPlaybackInfo {
  final String streamUrl;
  final Map<String, String> headers;
  final bool isHls;
  final String? licenseUrl;

  StreamPlaybackInfo({
    required this.streamUrl,
    this.headers = const {},
    this.isHls = true,
    this.licenseUrl,
  });
}

abstract class ILiveTvSource {
  String get sourceName;
  Future<List<ChannelModel>> fetchChannels();
  Future<List<EpgProgramModel>> fetchEpg(int channelId);
  Future<StreamPlaybackInfo> resolveStream(ChannelModel channel);
  void clearCache() {}
}

