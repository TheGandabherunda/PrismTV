import 'dart:js_interop';

@JS('prismSetQuality')
external bool _prismSetQuality(int targetHeight);

/// Web implementation utilizing the Hls.js JavaScript bridge
bool switchWebQuality(int targetHeight) {
  try {
    return _prismSetQuality(targetHeight);
  } catch (_) {
    return false;
  }
}

