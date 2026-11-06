/// Web / unsupported platform stub for LocalStreamProxy
class LocalStreamProxy {
  static Future<void> ensureStarted() async {}

  static String getProxiedUrl(String rawStreamUrl, {String? hdnea, int? channelId}) {
    return rawStreamUrl;
  }

  static String getProxiedMpdUrl(String rawStreamUrl, {String? hdnea, int? channelId}) {
    return rawStreamUrl;
  }

  static String getDrmLicenseUrl(String originalLicenseUrl, {int? channelId}) {
    return originalLicenseUrl;
  }

  static int get port => 0;
}
