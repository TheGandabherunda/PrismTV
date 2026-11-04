class ApiEndpoints {
  // Authentication & SSO
  static const String authDomain = 'tv.media.jio.com';
  static const String sendOtpUrl = 'https://tv.media.jio.com/apis/v2.0/loginotp/send';
  static const String verifyOtpUrl = 'https://tv.media.jio.com/apis/v2.0/loginotp/verify';
  static const String refreshOtpUrl = 'https://tv.media.jio.com/apis/v2.0/loginotp/refresh?langId=6';
  static const String refreshTokenServiceUrl = 'https://auth.media.jio.com/tokenservice/apis/v1/refreshtoken?langId=6';

  // Catalog & Channels
  static const String channelListUrl =
      'https://jiotv.data.cdn.jio.com/apis/v3.1/getMobileChannelList/get/?os=android&devicetype=phone&usertype=tvYR7NSNn7rymo3F';
  static const String channelLogoBaseUrl = 'https://jiotv.catchup.cdn.jio.com/dare_images/images/';

  // EPG (Electronic Program Guide)
  static const String epgUrl = 'https://jiotv.data.cdn.jio.com/apis/v1.3/getepg/get';
  static const String epgPosterBaseUrl = 'https://jiotv.catchup.cdn.jio.com/dare_images/shows/';

  // Playback & Stream Resolution
  static const String playbackBaseUrl = 'https://jiotvapi.media.jio.com/playback/apis/v1.1/geturl?langId=6';

  // Default Headers & Signatures
  static const String appKey = 'NzNiMDhlYzQ5NWJk';
  static const String appName = 'RJIL_JioTV';
  static const String defaultUserAgent =
      'plaYtv/7.0.8 (Linux;Android 11) ExoPlayerLib/2.11.7';
}

