import '../../core/constants/api_endpoints.dart';

class EpgProgramModel {
  final String showName;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? episodeTitle;
  final String? episodeNum;
  final String? posterUrl;
  final String? category;
  final List<String> genres;

  EpgProgramModel({
    required this.showName,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.episodeTitle,
    this.episodeNum,
    this.posterUrl,
    this.category,
    this.genres = const [],
  });

  bool get isNowPlaying {
    final now = DateTime.now();
    return (now.isAfter(startTime) || now.isAtSameMomentAs(startTime)) && now.isBefore(endTime);
  }

  double get progress {
    final now = DateTime.now();
    if (now.isBefore(startTime)) return 0.0;
    if (now.isAfter(endTime)) return 1.0;
    final totalDuration = endTime.difference(startTime).inSeconds;
    if (totalDuration <= 0) return 0.0;
    final elapsed = now.difference(startTime).inSeconds;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  static DateTime _parseEpoch(dynamic value, {required bool isStart}) {
    if (value != null) {
      final num? val = num.tryParse(value.toString());
      if (val != null && val > 0) {
        final int intVal = val.toInt();
        // If >= 10^11 (13 digits: 1793817000000), it's epoch milliseconds
        if (intVal > 100000000000) {
          return DateTime.fromMillisecondsSinceEpoch(intVal);
        }
        // Otherwise epoch seconds (10 digits: 1793817000)
        return DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
      }
    }
    final now = DateTime.now();
    return isStart ? now : now.add(const Duration(hours: 1));
  }

  factory EpgProgramModel.fromJson(Map<String, dynamic> json) {
    final String show = json['showname'] ?? json['showName'] ?? json['title'] ?? 'Live Broadcast';
    final String desc = json['description'] ?? json['episode_desc'] ?? json['desc'] ?? '';

    // startEpoch / endEpoch in Jio API are 13-digit epoch milliseconds
    final dynamic rawStart = json['startEpoch'] ?? json['startepoch'] ?? json['serverEpoch'] ?? json['startTime'];
    final dynamic rawEnd = json['endEpoch'] ?? json['endepoch'] ?? json['endTime'];

    final DateTime start = _parseEpoch(rawStart, isStart: true);
    final DateTime end = _parseEpoch(rawEnd, isStart: false);

    String? poster = json['episodePoster'] ?? json['episodeThumbnail'] ?? json['poster'];
    if (poster != null && poster.isNotEmpty) {
      if (!poster.startsWith('http://') && !poster.startsWith('https://')) {
        poster = '${ApiEndpoints.epgPosterBaseUrl}$poster';
      }
    }

    final rawGenres = json['showGenre'];
    final List<String> genreList = (rawGenres is List)
        ? rawGenres.map((e) => e.toString()).toList()
        : const [];

    return EpgProgramModel(
      showName: show,
      description: desc,
      startTime: start,
      endTime: end,
      episodeTitle: json['episode_title'] ?? json['episodeTitle'],
      episodeNum: json['episode_num']?.toString() ?? json['episodeNum']?.toString(),
      posterUrl: poster,
      category: json['showCategory']?.toString(),
      genres: genreList,
    );
  }
}

extension EpgListExtension on List<EpgProgramModel> {
  EpgProgramModel? get nowPlayingOrUpcoming {
    if (isEmpty) return null;
    final now = DateTime.now();

    // 1. Direct match: show that is actively playing right now
    for (final p in this) {
      if ((now.isAfter(p.startTime) || now.isAtSameMomentAs(p.startTime)) && now.isBefore(p.endTime)) {
        return p;
      }
    }

    // 2. Next best: show that started before now and ends closest to now
    final past = where((p) => p.startTime.isBefore(now) || p.startTime.isAtSameMomentAs(now)).toList();
    if (past.isNotEmpty) {
      past.sort((a, b) => b.startTime.compareTo(a.startTime));
      return past.first;
    }

    // 3. Otherwise: upcoming show closest to now
    final upcoming = where((p) => p.startTime.isAfter(now)).toList();
    if (upcoming.isNotEmpty) {
      upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
      return upcoming.first;
    }

    return first;
  }
}
