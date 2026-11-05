/// Stub implementation for non-web platforms (Android, iOS, Desktop)
bool switchWebQuality(int targetHeight) {
  return false;
}

List<Map<String, dynamic>> getWebQualityLevels() {
  return [];
}

List<Map<String, dynamic>> getWebAudioTracks() {
  return [];
}

bool switchWebAudioTrack(String trackIdOrLang) {
  return false;
}

void toggleWebFullscreen() {}

bool getWebIsFullscreen() => false;

void toggleWebPiP() {}

int getWebLiveDelay() => 0;

void webGoToLive() {}

void webResumeVideo() {}
