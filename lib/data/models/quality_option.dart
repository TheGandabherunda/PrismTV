class QualityOption {
  final String id;
  final String label;
  final String badge;
  final int minRate;
  final int maxRate;
  final int targetHeight; // 0 for auto, 1080, 720, 480, 360, 240

  const QualityOption({
    required this.id,
    required this.label,
    required this.badge,
    required this.minRate,
    required this.maxRate,
    this.targetHeight = 0,
  });

  static const List<QualityOption> defaultOptions = [
    QualityOption(
      id: 'auto',
      label: 'Auto (Recommended)',
      badge: 'Dynamic Adaptive',
      minRate: 80000,
      maxRate: 3500000,
      targetHeight: 0,
    ),
    QualityOption(
      id: '1080p',
      label: '1080p Full HD',
      badge: 'FHD • 3.0 Mbps',
      minRate: 2400000,
      maxRate: 3500000,
      targetHeight: 1080,
    ),
    QualityOption(
      id: '720p',
      label: '720p HD',
      badge: 'HD • 1.5 Mbps',
      minRate: 1200000,
      maxRate: 1800000,
      targetHeight: 720,
    ),
    QualityOption(
      id: '480p',
      label: '480p High',
      badge: 'SD • 800 Kbps',
      minRate: 650000,
      maxRate: 950000,
      targetHeight: 480,
    ),
    QualityOption(
      id: '360p',
      label: '360p Standard',
      badge: 'Low • 450 Kbps',
      minRate: 350000,
      maxRate: 600000,
      targetHeight: 360,
    ),
    QualityOption(
      id: '240p',
      label: '240p Data Saver',
      badge: 'Ultra Low • 200 Kbps',
      minRate: 80000,
      maxRate: 250000,
      targetHeight: 240,
    ),
  ];
}
