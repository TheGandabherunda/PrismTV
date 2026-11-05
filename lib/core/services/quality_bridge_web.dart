import 'dart:convert';
import 'dart:js_interop';

@JS('prismSetQuality')
external bool _prismSetQuality(int targetHeight);

@JS('prismGetQualityLevelsJson')
external JSString? _prismGetQualityLevelsJson();

@JS('prismGetAudioTracksJson')
external JSString? _prismGetAudioTracksJson();

@JS('prismSetAudioTrack')
external bool _prismSetAudioTrack(JSString trackIdOrLang);

@JS('prismToggleFullscreen')
external void _prismToggleFullscreen();

@JS('prismIsFullscreen')
external bool _prismIsFullscreen();

@JS('prismTogglePiP')
external void _prismTogglePiP();

@JS('prismGetLiveDelay')
external int _prismGetLiveDelay();

@JS('prismGoToLive')
external void _prismGoToLive();

@JS('prismResumeVideo')
external void _prismResumeVideo();

int getWebLiveDelay() {
  try {
    return _prismGetLiveDelay();
  } catch (_) {
    return 0;
  }
}

void webGoToLive() {
  try {
    _prismGoToLive();
  } catch (_) {}
}

void webResumeVideo() {
  try {
    _prismResumeVideo();
  } catch (_) {}
}

void toggleWebFullscreen() {
  try {
    _prismToggleFullscreen();
  } catch (_) {}
}

bool getWebIsFullscreen() {
  try {
    return _prismIsFullscreen();
  } catch (_) {
    return false;
  }
}

void toggleWebPiP() {
  try {
    _prismTogglePiP();
  } catch (_) {}
}

/// Web implementation utilizing the Hls.js & Shaka Player JavaScript bridge
bool switchWebQuality(int targetHeight) {
  try {
    return _prismSetQuality(targetHeight);
  } catch (_) {
    return false;
  }
}

List<Map<String, dynamic>> getWebQualityLevels() {
  try {
    final jsStr = _prismGetQualityLevelsJson();
    if (jsStr == null) return [];
    final raw = jsStr.toDart;
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return [];
  }
}

List<Map<String, dynamic>> getWebAudioTracks() {
  try {
    final jsStr = _prismGetAudioTracksJson();
    if (jsStr == null) return [];
    final raw = jsStr.toDart;
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return [];
  }
}

bool switchWebAudioTrack(String trackIdOrLang) {
  try {
    return _prismSetAudioTrack(trackIdOrLang.toJS);
  } catch (_) {
    return false;
  }
}
