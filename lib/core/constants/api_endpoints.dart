import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Base URLs (Automatically adapts for Native Android TV vs Web Browser Preview)
  static String get _apiBase =>
      kIsWeb ? '/api/proxy' : 'https://jiotvapi.media.jio.com';

  // Authentication & SSO
  static String get sendOtpUrl => '$_apiBase/userservice/apis/v1/loginotp/send';
  static String get verifyOtpUrl => '$_apiBase/userservice/apis/v1/loginotp/verify';
  static String get refreshOtpUrl =>
      kIsWeb ? '/api/proxy/apis/v2.0/loginotp/refresh?langId=6' : 'https://tv.media.jio.com/apis/v2.0/loginotp/refresh?langId=6';

  // Catalog & Channels (Public CDN with open CORS)
  static const String channelListUrl =
      'https://jiotv.data.cdn.jio.com/apis/v3.1/getMobileChannelList/get/?os=android&devicetype=phone&usertype=tvYR7NSNn7rymo3F';
  static const String channelLogoBaseUrl = 'https://jiotv.catchup.cdn.jio.com/dare_images/images/';

  // EPG (Electronic Program Guide)
  static const String epgUrl = 'https://jiotv.data.cdn.jio.com/apis/v1.3/getepg/get';
  static const String epgPosterBaseUrl = 'https://jiotv.catchup.cdn.jio.com/dare_images/shows/';

  // Playback & Stream Resolution
  static String get playbackBaseUrl => '$_apiBase/playback/apis/v1.1/geturl?langId=6';

  // Default Headers & Signatures
  static const String appKey = 'NzNiMDhlYzQyNjJm';
  static const String appName = 'RJIL_JioTV';
  static const String defaultUserAgent =
      'plaYtv/7.0.8 (Linux;Android 11) ExoPlayerLib/2.11.7';
}
