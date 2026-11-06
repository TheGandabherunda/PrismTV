import '../../core/constants/api_endpoints.dart';
import 'auth_session.dart';

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
  final bool isPremium;
  final String planType;
  final String businessType;
  final List<String> packageIds;
  final String channelPrice;
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
    this.isPremium = false,
    this.planType = '',
    this.businessType = '',
    this.packageIds = const [],
    this.channelPrice = '',
    this.isFavorite = false,
  });

  static final ChannelModel fallback = ChannelModel(
    channelId: 3585,
    channelName: 'Sony Sports Ten 4 HD',
    logoUrl: '',
    categoryId: 3,
    categoryName: 'Sports',
    languageId: 13,
    languageName: 'Kannada',
    isPremium: true,
    planType: 'premium',
    businessType: 'premium',
    packageIds: const ['1', '6', '7', '23'],
  );

  String get fullLogoUrl {
    if (logoUrl.startsWith('http')) return logoUrl;
    return '${ApiEndpoints.channelLogoBaseUrl}$logoUrl';
  }

  String get languageCode {
    switch (languageId) {
      case 13: return 'kn'; // Kannada
      case 11: return 'te'; // Telugu
      case 8:  return 'ta'; // Tamil
      case 7:  return 'ml'; // Malayalam
      case 1:  return 'hi'; // Hindi
      case 2:  return 'mr'; // Marathi
      case 5:  return 'bn'; // Bengali
      case 9:  return 'gu'; // Gujarati
      case 3:  return 'pa'; // Punjabi
      case 4:  return 'ur'; // Urdu
      case 10: return 'or'; // Odia
      case 12: return 'bho'; // Bhojpuri
      case 14: return 'as'; // Assamese
      case 6:  return 'en'; // English
      default: return 'en';
    }
  }

  /// Evaluates whether this channel is included in the logged-in mobile number's active subscription plans
  bool isSubscribedFor(AuthSession? session, {Set<int>? restrictedIds}) {
    // 0. If marked as restricted / blocked by broadcaster on this account/device, never show
    if (restrictedIds != null && restrictedIds.contains(channelId)) {
      return false;
    }

    // 1. Free-to-Air / Open channels (DD channels, state broadcasts, free public feeds)
    final bType = businessType.toLowerCase().trim();
    final pType = planType.toLowerCase().trim();
    final isFree = bType == 'free' ||
        bType == 'guest' ||
        (bType.isEmpty && pType == 'free') ||
        (channelPrice.contains('0.00') && !isPremium && bType != 'premium');
    if (isFree) return true;

    // 2. Unauthenticated user: only free-to-air channels are viewable
    if (session == null || !session.isValid) {
      return false;
    }

    // 3. Premium channels (Colors HD, Sony Ten, Sony SAB, Star Gold, Cartoon Network, Discovery, etc.)
    // In Jio v3.1 catalog, business_type == 'premium' strictly designates paywall/premium live channels
    final isPrem = bType == 'premium' || (bType.isEmpty && isPremium);
    if (isPrem) {
      // Must hold an active premium live subscription on this Jio mobile number
      return session.hasActivePremium;
    }

    // 4. Standard Jio channels (CNBC, Colors Super, etc.)
    if (bType == 'jio' || packageIds.contains('1')) {
      return session.hasActiveJioBase;
    }

    // 5. Specific package IDs restriction (if channel requires a custom package that doesn't include '1')
    if (packageIds.isNotEmpty && !packageIds.contains('1')) {
      final matchesPackage = packageIds.any((pkg) => session.activePlanIds.contains(pkg));
      if (!matchesPackage && !session.hasActivePremium) {
        return false;
      }
    }

    return session.hasActiveJioBase;
  }

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    final int catId = int.tryParse(json['channelCategoryId']?.toString() ?? '1') ?? 1;
    final int langId = int.tryParse(json['channelLanguageId']?.toString() ?? '6') ?? 6;
    final String name = json['channel_name'] ?? json['name'] ?? 'Channel';
    final bool hd = name.toUpperCase().contains('HD') || (json['isHD'] == true || json['isHD'] == 1);

    final rawPkgs = json['packageIds'];
    final List<String> pkgs = (rawPkgs is List)
        ? rawPkgs.map((e) => e.toString().trim()).toList()
        : const [];

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
      isPremium: json['is_premium'] == true || json['isPremium'] == true,
      planType: json['plan_type']?.toString().toLowerCase().trim() ?? json['planType']?.toString().toLowerCase().trim() ?? '',
      businessType: json['business_type']?.toString().toLowerCase().trim() ?? json['businessType']?.toString().toLowerCase().trim() ?? '',
      packageIds: pkgs,
      channelPrice: json['channelPrice']?.toString() ?? '',
      isFavorite: json['isFavorite'] == true,
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
      'is_premium': isPremium,
      'plan_type': planType,
      'business_type': businessType,
      'packageIds': packageIds,
      'channelPrice': channelPrice,
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
