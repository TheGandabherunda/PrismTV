import 'package:flutter/foundation.dart';
import '../storage/hive_service.dart';

class ApiEndpoints {
  // Base URLs (Direct Native Connections for Android TV & Mobile; Local Proxy for Web Dev)
  static String get proxyHost {
    if (!kIsWeb) return '';
    try {
      final custom = HiveService.getCustomProxyUrl();
      if (custom != null && custom.trim().isNotEmpty) {
        return custom.trim().replaceAll(RegExp(r'/+$'), '');
      }
    } catch (_) {}
    return '';
  }

  static String get _apiBase {
    if (!kIsWeb) return 'https://jiotvapi.media.jio.com';
    if (proxyHost.isNotEmpty) return '$proxyHost/api/proxy';
    return '/api/proxy';
  }

  static String get streamProxyUrl {
    if (proxyHost.isNotEmpty) return '$proxyHost/api/stream-proxy';
    return '/api/stream-proxy';
  }

  // Authentication & SSO
  static String get sendOtpUrl => '$_apiBase/userservice/apis/v1/loginotp/send';
  static String get verifyOtpUrl => '$_apiBase/userservice/apis/v1/loginotp/verify';
  static String get refreshOtpUrl {
    if (!kIsWeb) return 'https://tv.media.jio.com/apis/v2.0/loginotp/refresh?langId=6';
    if (proxyHost.isNotEmpty) return '$proxyHost/api/proxy/apis/v2.0/loginotp/refresh?langId=6';
    return '/api/proxy/apis/v2.0/loginotp/refresh?langId=6';
  }

  // Catalog & Channels (v3.1 includes real subscription flags: is_premium, business_type, plan_type, packageIds)
  static String get channelListUrl {
    if (!kIsWeb) {
      return 'https://jiotv.data.cdn.jio.com/apis/v3.1/getMobileChannelList/get/?os=android&devicetype=phone&usertype=tvYR7NSNn7rymo3F';
    }
    return '$_apiBase/apis/v3.1/getMobileChannelList/get/?os=android&devicetype=phone&usertype=tvYR7NSNn7rymo3F';
  }

  static String get fallbackChannelListUrl {
    if (!kIsWeb) {
      return 'https://jiotv.data.cdn.jio.com/apis/v1.4/getMobileChannelList/get/?langId=6&os=android&devicetype=phone';
    }
    return '$_apiBase/apis/v1.4/getMobileChannelList/get/?langId=6&os=android&devicetype=phone';
  }

  static const String channelLogoBaseUrl = 'https://jiotv.catchup.cdn.jio.com/dare_images/images/';

  // EPG (Electronic Program Guide)
  static String get epgUrl {
    if (!kIsWeb) {
      return 'https://jiotv.data.cdn.jio.com/apis/v1.3/getepg/get';
    }
    return '$_apiBase/apis/v1.3/getepg/get';
  }
  static const String epgPosterBaseUrl = 'https://jiotv.catchup.cdn.jio.com/dare_images/shows/';

  // Playback & Stream Resolution
  static String get playbackBaseUrl => '$_apiBase/playback/apis/v1.1/geturl?langId=6';

  // Default Headers & Signatures
  static const String appKey = 'NzNiMDhlYzQyNjJm';
  static const String appName = 'RJIL_JioTV';
  static const String defaultUserAgent =
      'okhttp/4.12.0';
}
