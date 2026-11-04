class EpgProgramModel {
  final String showName;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? episodeTitle;
  final String? episodeNum;
  final String? posterUrl;

  EpgProgramModel({
    required this.showName,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.episodeTitle,
    this.episodeNum,
    this.posterUrl,
  });

  bool get isNowPlaying {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
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

  factory EpgProgramModel.fromJson(Map<String, dynamic> json) {
    // Jio EPG format parser
    final String show = json['showname'] ?? json['title'] ?? 'Live Broadcast';
    final String desc = json['description'] ?? json['desc'] ?? '';
    
    // starttime & endtime often in milliseconds or epoch format
    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(const Duration(hours: 1));

    if (json['startepoch'] != null) {
      final epoch = int.tryParse(json['startepoch'].toString()) ?? 0;
      if (epoch > 0) start = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    }
    if (json['endepoch'] != null) {
      final epoch = int.tryParse(json['endepoch'].toString()) ?? 0;
      if (epoch > 0) end = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    }

    return EpgProgramModel(
      showName: show,
      description: desc,
      startTime: start,
      endTime: end,
      episodeTitle: json['episode_title'],
      episodeNum: json['episode_num']?.toString(),
      posterUrl: json['episodePoster'] ?? json['poster'],
    );
  }
}

