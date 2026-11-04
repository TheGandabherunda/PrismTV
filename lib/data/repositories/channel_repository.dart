import '../../core/storage/hive_service.dart';
import '../models/channel_model.dart';
import '../models/epg_program_model.dart';
import '../providers/i_live_tv_source.dart';

class ChannelRepository {
  final ILiveTvSource _liveSource;

  ChannelRepository(this._liveSource);

  Future<List<ChannelModel>> getChannels() async {
    return _liveSource.fetchChannels();
  }

  Future<List<EpgProgramModel>> getEpg(int channelId) async {
    return _liveSource.fetchEpg(channelId);
  }

  Future<StreamPlaybackInfo> getStream(ChannelModel channel) async {
    return _liveSource.resolveStream(channel);
  }

  Future<void> toggleFavorite(ChannelModel channel) async {
    await HiveService.toggleFavorite(channel.channelId);
    channel.isFavorite = !channel.isFavorite;
  }
}

