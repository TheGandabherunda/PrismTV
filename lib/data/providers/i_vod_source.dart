import 'i_live_tv_source.dart';

class VodItemModel {
  final String id;
  final String title;
  final String? posterUrl;
  final String? backdropUrl;
  final String? synopsis;
  final int? releaseYear;
  final String? duration;
  final String? genre;
  final double? rating;

  VodItemModel({
    required this.id,
    required this.title,
    this.posterUrl,
    this.backdropUrl,
    this.synopsis,
    this.releaseYear,
    this.duration,
    this.genre,
    this.rating,
  });
}

abstract class IVodSource {
  String get sourceName;
  Future<List<VodItemModel>> fetchMovies({String? category});
  Future<List<VodItemModel>> fetchTvShows();
  Future<StreamPlaybackInfo> resolveVodStream(String contentId);
}

