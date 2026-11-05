class QualityOption {
  final String id;
  final String label;
  final String badge;
  final int minRate;
  final int maxRate;
  final int targetHeight; // 0 for auto, 1080, 720, 576, 540, 480, 360, 180, etc.
  final bool isActive;

  const QualityOption({
    required this.id,
    required this.label,
    required this.badge,
    this.minRate = 80000,
    this.maxRate = 4500000,
    this.targetHeight = 0,
    this.isActive = false,
  });

  QualityOption copyWith({
    String? id,
    String? label,
    String? badge,
    int? minRate,
    int? maxRate,
    int? targetHeight,
    bool? isActive,
  }) {
    return QualityOption(
      id: id ?? this.id,
      label: label ?? this.label,
      badge: badge ?? this.badge,
      minRate: minRate ?? this.minRate,
      maxRate: maxRate ?? this.maxRate,
      targetHeight: targetHeight ?? this.targetHeight,
      isActive: isActive ?? this.isActive,
    );
  }

  factory QualityOption.fromJson(Map<String, dynamic> json) {
    final h = (json['height'] as num?)?.toInt() ?? 0;
    final id = json['id']?.toString() ?? (h > 0 ? '${h}p' : 'auto');
    final label = json['label']?.toString() ?? (h > 0 ? '${h}p' : 'Auto');
    final badge = json['badge']?.toString() ?? '';
    final bw = (json['bandwidth'] as num?)?.toInt() ?? 4500000;
    final active = json['active'] == true;

    return QualityOption(
      id: id,
      label: label,
      badge: badge,
      minRate: 80000,
      maxRate: bw,
      targetHeight: h,
      isActive: active,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'badge': badge,
      'minRate': minRate,
      'maxRate': maxRate,
      'targetHeight': targetHeight,
      'active': isActive,
    };
  }

  static const List<QualityOption> defaultOptions = [
    QualityOption(
      id: 'auto',
      label: 'Auto (Recommended)',
      badge: 'Dynamic Adaptive',
      minRate: 80000,
      maxRate: 4500000,
      targetHeight: 0,
    ),
    QualityOption(
      id: '1080p',
      label: '1080p Full HD',
      badge: 'FHD • 3.0 Mbps',
      minRate: 80000,
      maxRate: 4500000,
      targetHeight: 1080,
    ),
    QualityOption(
      id: '720p',
      label: '720p HD',
      badge: 'HD • 1.5 Mbps',
      minRate: 80000,
      maxRate: 2200000,
      targetHeight: 720,
    ),
    QualityOption(
      id: '540p',
      label: '540p Standard',
      badge: 'SD • 650 Kbps',
      minRate: 80000,
      maxRate: 950000,
      targetHeight: 540,
    ),
    QualityOption(
      id: '360p',
      label: '360p Medium',
      badge: 'Low • 300 Kbps',
      minRate: 80000,
      maxRate: 600000,
      targetHeight: 360,
    ),
    QualityOption(
      id: '180p',
      label: '180p Low',
      badge: 'Ultra Low • 150 Kbps',
      minRate: 80000,
      maxRate: 250000,
      targetHeight: 180,
    ),
  ];

  static QualityOption fromId(String? id) {
    if (id == null || id.isEmpty) return defaultOptions.first;
    return defaultOptions.firstWhere(
      (o) => o.id.toLowerCase() == id.toLowerCase(),
      orElse: () => defaultOptions.first,
    );
  }
}
