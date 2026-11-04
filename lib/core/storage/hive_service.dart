import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/auth_session.dart';

class HiveService {
  static const String authBoxName = 'prism_auth_box';
  static const String cacheBoxName = 'prism_cache_box';
  static const String settingsBoxName = 'prism_settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(authBoxName);
    await Hive.openBox(cacheBoxName);
    await Hive.openBox(settingsBoxName);
  }

  // Auth Operations
  static AuthSession? getSavedSession() {
    try {
      final box = Hive.box(authBoxName);
      final raw = box.get('current_session');
      if (raw != null) {
        if (raw is Map) {
          return AuthSession.fromJson(Map<String, dynamic>.from(raw));
        } else if (raw is String) {
          return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('[HIVE_AUTH_ERROR] $e');
    }
    return null;
  }

  static Future<void> saveSession(AuthSession session) async {
    final box = Hive.box(authBoxName);
    await box.put('current_session', session.toJson());
  }

  static Future<void> clearSession() async {
    final box = Hive.box(authBoxName);
    await box.delete('current_session');
  }

  // Favorites
  static List<int> getFavoriteChannelIds() {
    final box = Hive.box(settingsBoxName);
    final list = box.get('favorite_channels', defaultValue: <dynamic>[]);
    return List<int>.from(list);
  }

  static Future<void> toggleFavorite(int channelId) async {
    final box = Hive.box(settingsBoxName);
    final list = getFavoriteChannelIds();
    if (list.contains(channelId)) {
      list.remove(channelId);
    } else {
      list.add(channelId);
    }
    await box.put('favorite_channels', list);
  }

  // Settings
  static String getPreferredQuality() {
    final box = Hive.box(settingsBoxName);
    return box.get('preferred_quality', defaultValue: 'Auto');
  }

  static Future<void> setPreferredQuality(String quality) async {
    final box = Hive.box(settingsBoxName);
    await box.put('preferred_quality', quality);
  }

  static String? getCustomProxyUrl() {
    final box = Hive.box(settingsBoxName);
    return box.get('custom_proxy_url') as String?;
  }

  static Future<void> setCustomProxyUrl(String? url) async {
    final box = Hive.box(settingsBoxName);
    if (url == null || url.trim().isEmpty) {
      await box.delete('custom_proxy_url');
    } else {
      await box.put('custom_proxy_url', url.trim());
    }
  }
}

