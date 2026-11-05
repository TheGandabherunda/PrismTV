class AudioTrackOption {
  final String id;
  final String language;
  final String label;
  final bool isActive;

  const AudioTrackOption({
    required this.id,
    required this.language,
    required this.label,
    this.isActive = false,
  });

  factory AudioTrackOption.fromJson(Map<String, dynamic> json) {
    return AudioTrackOption(
      id: json['id']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Default Audio',
      isActive: json['active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language': language,
      'label': label,
      'active': isActive,
    };
  }

  AudioTrackOption copyWith({
    String? id,
    String? language,
    String? label,
    bool? isActive,
  }) {
    return AudioTrackOption(
      id: id ?? this.id,
      language: language ?? this.language,
      label: label ?? this.label,
      isActive: isActive ?? this.isActive,
    );
  }
}

