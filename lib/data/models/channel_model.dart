import '../../core/constants/api_endpoints.dart';

class ChannelModel {
  final int channelId;
  final String channelName;
  final String logoUrl;
  final int categoryId;
  final String categoryName;
  final int languageId;
  final String languageName;
  final bool isHd;
  final bool isCatchupAvailable;
  bool isFavorite;

  ChannelModel({
    required this.channelId,
    required this.channelName,
    required this.logoUrl,
    required this.categoryId,
    required this.categoryName,
    required this.languageId,
    required this.languageName,
    this.isHd = false,
    this.isCatchupAvailable = false,
    this.isFavorite = false,
  });

  String get fullLogoUrl {
    if (logoUrl.startsWith('http')) return logoUrl;
    return '${ApiEndpoints.channelLogoBaseUrl}$logoUrl';
  }

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    final int catId = int.tryParse(json['channelCategoryId']?.toString() ?? '1') ?? 1;
    final int langId = int.tryParse(json['channelLanguageId']?.toString() ?? '6') ?? 6;
    final String name = json['channel_name'] ?? json['name'] ?? 'Channel';
    final bool hd = name.toUpperCase().contains('HD') || (json['isHD'] == true || json['isHD'] == 1);

    return ChannelModel(
      channelId: int.tryParse(json['channel_id']?.toString() ?? '0') ?? 0,
      channelName: name,
      logoUrl: json['logoUrl'] ?? '',
      categoryId: catId,
      categoryName: _resolveCategory(catId),
      languageId: langId,
      languageName: _resolveLanguage(langId),
      isHd: hd,
      isCatchupAvailable: json['isCatchupAvailable'] == true || json['isCatchupAvailable'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel_id': channelId,
      'channel_name': channelName,
      'logoUrl': logoUrl,
      'channelCategoryId': categoryId,
      'channelLanguageId': languageId,
      'isHD': isHd,
      'isCatchupAvailable': isCatchupAvailable,
      'isFavorite': isFavorite,
    };
  }

  static String _resolveCategory(int id) {
    switch (id) {
      case 5:
        return 'Entertainment';
      case 6:
        return 'Movies';
      case 7:
        return 'Kids';
      case 8:
        return 'Sports';
      case 9:
        return 'Lifestyle';
      case 10:
        return 'Infotainment';
      case 12:
        return 'News';
      case 13:
        return 'Music';
      case 15:
        return 'Devotional';
      case 16:
        return 'Business';
      case 17:
        return 'Educational';
      case 18:
        return 'Shopping';
      default:
        return 'General';
    }
  }

  static String _resolveLanguage(int id) {
    switch (id) {
      case 13:
        return 'Kannada';
      case 6:
        return 'English';
      case 1:
        return 'Hindi';
      case 8:
        return 'Tamil';
      case 11:
        return 'Telugu';
      case 7:
        return 'Malayalam';
      case 2:
        return 'Marathi';
      case 5:
        return 'Bengali';
      case 9:
        return 'Gujarati';
      case 3:
        return 'Punjabi';
      default:
        return 'Other';
    }
  }
}

