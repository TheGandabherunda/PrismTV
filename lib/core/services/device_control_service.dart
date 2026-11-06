import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hardware device controller for Brightness and System Volume.
/// Uses native MethodChannels on Android for 0ms direct OS integration,
/// and falls back gracefully on Web / Desktop.
class DeviceControlService {
  static const MethodChannel _channel = MethodChannel('org.thegandabherunda.prismtv/device_control');

  static double _cachedBrightness = 0.5;
  static double _cachedVolume = 0.5;

  static double get cachedBrightness => _cachedBrightness;
  static double get cachedVolume => _cachedVolume;

  /// Fetches the current hardware screen brightness (0.0 to 1.0)
  static Future<double> getBrightness() async {
    if (kIsWeb) return _cachedBrightness;
    try {
      final double? b = await _channel.invokeMethod<double>('getBrightness');
      if (b != null) {
        _cachedBrightness = b.clamp(0.01, 1.0);
        return _cachedBrightness;
      }
    } catch (e) {
      debugPrint('[DEVICE_CONTROL] Failed to get brightness: $e');
    }
    return _cachedBrightness;
  }

  /// Sets the hardware screen brightness (0.01 to 1.0)
  static Future<void> setBrightness(double value) async {
    final clamped = value.clamp(0.01, 1.0);
    _cachedBrightness = clamped;
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('setBrightness', {'brightness': clamped});
    } catch (e) {
      debugPrint('[DEVICE_CONTROL] Failed to set brightness: $e');
    }
  }

  /// Fetches the current system media volume (0.0 to 1.0)
  static Future<double> getVolume() async {
    if (kIsWeb) return _cachedVolume;
    try {
      final double? v = await _channel.invokeMethod<double>('getVolume');
      if (v != null) {
        _cachedVolume = v.clamp(0.0, 1.0);
        return _cachedVolume;
      }
    } catch (e) {
      debugPrint('[DEVICE_CONTROL] Failed to get volume: $e');
    }
    return _cachedVolume;
  }

  /// Sets the system media volume (0.0 to 1.0)
  static Future<void> setVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    _cachedVolume = clamped;
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('setVolume', {'volume': clamped});
    } catch (e) {
      debugPrint('[DEVICE_CONTROL] Failed to set volume: $e');
    }
  }
}

