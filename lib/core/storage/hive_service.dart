import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../../data/models/auth_session.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/quality_option.dart';

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

  // Broadcaster Blocked / Restricted Channels for this subscriber
  static Set<int> getRestrictedChannelIds() {
    try {
      final box = Hive.box(settingsBoxName);
      final list = box.get('restricted_channels', defaultValue: <dynamic>[]);
      return Set<int>.from(list);
    } catch (_) {
      return {};
    }
  }

  static bool isChannelRestricted(int channelId) {
    return getRestrictedChannelIds().contains(channelId);
  }

  static Future<void> addRestrictedChannelId(int channelId) async {
    try {
      final box = Hive.box(settingsBoxName);
      final set = getRestrictedChannelIds();
      if (!set.contains(channelId)) {
        set.add(channelId);
        await box.put('restricted_channels', set.toList());
      }
    } catch (_) {}
  }

  static Future<void> clearRestrictedChannelIds() async {
    try {
      final box = Hive.box(settingsBoxName);
      await box.delete('restricted_channels');
    } catch (_) {}
  }

  // Settings
  static QualityOption getPreferredQualityOption() {
    try {
      final box = Hive.box(settingsBoxName);
      final id = box.get('preferred_quality_id', defaultValue: 'auto') as String;
      return QualityOption.fromId(id);
    } catch (_) {
      return QualityOption.defaultOptions.first;
    }
  }

  static Future<void> setPreferredQualityOption(QualityOption option) async {
    final box = Hive.box(settingsBoxName);
    await box.put('preferred_quality_id', option.id);
    await box.put('preferred_quality', option.label);
  }

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

  // Last Played Channel & Cache (for browser reload & instant resume)
  static ChannelModel? getLastPlayedChannel() {
    try {
      final box = Hive.box(cacheBoxName);
      final raw = box.get('last_played_channel');
      if (raw != null) {
        if (raw is Map) {
          return ChannelModel.fromJson(Map<String, dynamic>.from(raw));
        } else if (raw is String) {
          return ChannelModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('[HIVE_CHANNEL_ERROR] $e');
    }
    return null;
  }

  static Future<void> saveLastPlayedChannel(ChannelModel channel) async {
    try {
      final box = Hive.box(cacheBoxName);
      await box.put('last_played_channel', channel.toJson());
    } catch (_) {}
  }

  static List<ChannelModel> getCachedChannels() {
    try {
      final box = Hive.box(cacheBoxName);
      final raw = box.get('cached_channels_list');
      if (raw is List) {
        return raw.map((item) {
          if (item is Map) {
            return ChannelModel.fromJson(Map<String, dynamic>.from(item));
          } else if (item is String) {
            return ChannelModel.fromJson(jsonDecode(item) as Map<String, dynamic>);
          }
          return null;
        }).whereType<ChannelModel>().toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<void> saveCachedChannels(List<ChannelModel> channels) async {
    try {
      final box = Hive.box(cacheBoxName);
      await box.put('cached_channels_list', channels.map((c) => c.toJson()).toList());
    } catch (_) {}
  }
}

