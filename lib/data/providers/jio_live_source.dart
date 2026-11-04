import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_endpoints.dart';
import '../../core/storage/hive_service.dart';
import '../models/auth_session.dart';
import '../models/channel_model.dart';
import '../models/epg_program_model.dart';
import 'i_live_tv_source.dart';

class JioLiveSource implements ILiveTvSource {
  @override
  String get sourceName => 'JioLive';

  // In-memory cache for fast switching
  List<ChannelModel>? _cachedChannels;

  // ---------------------------------------------------------------------------
  // AUTHENTICATION APIs
  // ---------------------------------------------------------------------------

  /// Sends OTP to the given mobile number (+91...)
  Future<bool> sendOtp(String mobileNumber) async {
    try {
      final formattedNumber = mobileNumber.startsWith('+91')
          ? mobileNumber
          : '+91${mobileNumber.replaceAll(RegExp(r'\D'), '')}';
      
      final encodedNumber = base64Encode(utf8.encode(formattedNumber));

      final response = await http.post(
        Uri.parse(ApiEndpoints.sendOtpUrl),
        headers: {
          'Content-Type': 'application/json',
          'appname': ApiEndpoints.appName,
          'os': 'android',
          'devicetype': 'phone',
          'User-Agent': ApiEndpoints.defaultUserAgent,
        },
        body: jsonEncode({
          'number': encodedNumber,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  /// Verifies OTP and returns an AuthSession
  Future<AuthSession?> verifyOtp(String mobileNumber, String otp) async {
    try {
      final formattedNumber = mobileNumber.startsWith('+91')
          ? mobileNumber
          : '+91${mobileNumber.replaceAll(RegExp(r'\D'), '')}';
      final encodedNumber = base64Encode(utf8.encode(formattedNumber));

      final response = await http.post(
        Uri.parse(ApiEndpoints.verifyOtpUrl),
        headers: {
          'Content-Type': 'application/json',
          'appname': ApiEndpoints.appName,
          'os': 'android',
          'devicetype': 'phone',
          'User-Agent': ApiEndpoints.defaultUserAgent,
        },
        body: jsonEncode({
          'number': encodedNumber,
          'otp': otp.trim(),
          'deviceInfo': {
            'consumptionDeviceName': 'SM-G930F',
            'info': {
              'type': 'android',
              'platform': {'name': 'SM-G930F'},
              'androidId': '689f928e469502ab',
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final authToken = data['authToken'] ?? data['accessToken'] ?? '';
        final refreshToken = data['refreshToken'] ?? '';
        final ssoToken = data['ssoToken'] ?? '';
        final sessionAttrs = data['sessionAttributes'] ?? {};
        final userAttrs = sessionAttrs['user'] ?? {};
        final uniqueId = userAttrs['unique'] ?? userAttrs['uniqueId'] ?? '';
        final crmid = userAttrs['subscriberId'] ?? userAttrs['crmid'] ?? '';

        if (authToken.isNotEmpty && ssoToken.isNotEmpty) {
          final session = AuthSession(
            accessToken: authToken,
            refreshToken: refreshToken,
            ssoToken: ssoToken,
            uniqueId: uniqueId,
            crmid: crmid,
            subscriberId: crmid,
            mobileNumber: formattedNumber,
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          );
          await HiveService.saveSession(session);
          return session;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Refreshes the existing session SSO token
  Future<AuthSession?> refreshSession(AuthSession currentSession) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.refreshOtpUrl),
        headers: {
          'ssoToken': currentSession.ssoToken,
          'ssotoken': currentSession.ssoToken,
          'uniqueid': currentSession.uniqueId,
          'deviceid': '689f928e469502ab',
          'devicetype': 'phone',
          'os': 'android',
          'versionCode': '422',
          'User-Agent': 'okhttp/4.12.0',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['ssoToken'] ?? currentSession.ssoToken;
        final updated = AuthSession(
          accessToken: currentSession.accessToken,
          refreshToken: currentSession.refreshToken,
          ssoToken: newToken,
          uniqueId: currentSession.uniqueId,
          crmid: currentSession.crmid,
          subscriberId: currentSession.subscriberId,
          mobileNumber: currentSession.mobileNumber,
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );
        await HiveService.saveSession(updated);
        return updated;
      }
    } catch (_) {}
    return currentSession;
  }

  // ---------------------------------------------------------------------------
  // CHANNEL CATALOG & EPG
  // ---------------------------------------------------------------------------

  @override
  Future<List<ChannelModel>> fetchChannels() async {
    if (_cachedChannels != null && _cachedChannels!.isNotEmpty) {
      return _cachedChannels!;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.channelListUrl),
        headers: {
          'User-Agent': ApiEndpoints.defaultUserAgent,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['result'] ?? [];
        final favs = HiveService.getFavoriteChannelIds();

        final channels = list.map((item) {
          final model = ChannelModel.fromJson(item as Map<String, dynamic>);
          model.isFavorite = favs.contains(model.channelId);
          return model;
        }).toList();

        // Deduplicate duplicate SD channel aliases (e.g. Colors Kannada SD, Colors SD, Colors Marathi SD, etc.)
        final sdDuplicateIds = {1368, 1369, 1370, 1325, 1326};
        channels.removeWhere((c) {
          if (sdDuplicateIds.contains(c.channelId)) return true;
          final nameLower = c.channelName.toLowerCase().trim();
          if (nameLower.endsWith(' sd')) {
            final baseName = nameLower.substring(0, nameLower.length - 3).trim();
            final hasHd = channels.any((other) =>
                other.channelId != c.channelId &&
                other.channelName.toLowerCase().trim() == '$baseName hd');
            if (hasHd) return true;
          }
          return false;
        });

        // Sort: Favorites first, then Kannada channels, then others
        channels.sort((a, b) {
          if (a.isFavorite && !b.isFavorite) return -1;
          if (!a.isFavorite && b.isFavorite) return 1;
          if (a.languageId == 13 && b.languageId != 13) return -1;
          if (a.languageId != 13 && b.languageId == 13) return 1;
          return a.channelName.compareTo(b.channelName);
        });

        _cachedChannels = channels;
        return channels;
      }
    } catch (_) {}

    // Fallback default sample channels if network is unreachable
    return _buildSampleChannels();
  }

  @override
  Future<List<EpgProgramModel>> fetchEpg(int channelId) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.epgUrl}?offset=0&channel_id=$channelId');
      final response = await http.get(
        uri,
        headers: {'User-Agent': ApiEndpoints.defaultUserAgent},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['epg'] ?? [];
        return list
            .map((item) => EpgProgramModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // Fallback EPG entry
    final now = DateTime.now();
    return [
      EpgProgramModel(
        showName: 'Live Broadcast',
        description: 'Now streaming on PrismTV live broadcast network.',
        startTime: now.subtract(const Duration(minutes: 15)),
        endTime: now.add(const Duration(minutes: 45)),
      ),
      EpgProgramModel(
        showName: 'Prime Time Spotlight',
        description: 'Upcoming scheduled prime time feature broadcast.',
        startTime: now.add(const Duration(minutes: 45)),
        endTime: now.add(const Duration(minutes: 105)),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // STREAM RESOLUTION
  // ---------------------------------------------------------------------------

  @override
  Future<StreamPlaybackInfo> resolveStream(ChannelModel channel) async {
    final session = HiveService.getSavedSession();

    if (session == null || !session.isValid) {
      throw Exception('Authentication required. Please log in with your Jio number to stream live TV.');
    }

    try {
      final now = DateTime.now().toUtc();
      String pad(int n) => n.toString().padLeft(2, '0');
      final yyyy = now.year.toString();
      final mm = pad(now.month);
      final dd = pad(now.day);
      final hh = pad(now.hour);
      final mi = pad(now.minute);
      final ss = pad(now.second);
      final beginStr = '$yyyy$mm${dd}T$hh$mi$ss';
      final srnoStr = '$yyyy$mm$dd';

      // Jio origin mapping:
      // Channel 757 ("Colors Kannada HD") mobile HLS feed is capped at 360p,
      // while channel 1370 ("Colors_Kannada_SD_MOB", marked isHD: true) broadcasts the full 1080p 2.8 Mbps stream.
      int effectiveChannelId = channel.channelId;
      if (channel.channelId == 757) {
        effectiveChannelId = 1370;
      }

      final formBody = 'channel_id=$effectiveChannelId&stream_type=Seek&begin=$beginStr&srno=$srnoStr';

      final requestHeaders = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'appkey': 'NzNiMDhlYzQyNjJm',
        'channel_id': effectiveChannelId.toString(),
        'crmid': session.crmid,
        'userId': session.crmid,
        'subscriberId': session.crmid,
        'uniqueId': session.uniqueId,
        'deviceId': '689f928e469502ab',
        'devicetype': 'phone',
        'isott': 'false',
        'languageId': '6',
        'lbcookie': '1',
        'os': 'android',
        'osVersion': '13',
        'usergroup': 'tvYR7NSNn7rymo3F',
        'User-Agent': 'okhttp/4.12.0',
        'versionCode': '422',
        'accessToken': session.accessToken,
        'accesstoken': session.accessToken,
        'ssoToken': session.ssoToken,
        'ssotoken': session.ssoToken,
      };

      final response = await http.post(
        Uri.parse(ApiEndpoints.playbackBaseUrl),
        headers: requestHeaders,
        body: formBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bitrates = data['bitrates'] as Map<String, dynamic>?;

        // Use the complete master manifest (result / auto) which contains all video tracks.
        // Never use bitrates['high'] directly because on several entertainment/regional feeds
        // it filters out all video variants, resulting in a black screen (audio-only).
        String rawStreamUrl = data['result'] ?? '';
        if (rawStreamUrl.isEmpty && bitrates != null) {
          rawStreamUrl = bitrates['auto'] ?? bitrates['high'] ?? '';
        }

        if (rawStreamUrl.isNotEmpty) {
          // Extract hdnea if present anywhere
          String hdnea = '';
          final match = RegExp(r'hdnea=([^&]+)').firstMatch(rawStreamUrl);
          if (match != null) {
            hdnea = match.group(1) ?? '';
          }

          if (hdnea.isNotEmpty && !rawStreamUrl.contains('hdnea=')) {
            final sep = rawStreamUrl.contains('?') ? '&' : '?';
            rawStreamUrl = '$rawStreamUrl${sep}hdnea=$hdnea';
          }

          // On Web, route through local stream proxy to bypass browser CORS and deliver authentication
          final queryParams = <String, String>{
            'url': rawStreamUrl,
            'ssotoken': session.ssoToken,
            'accesstoken': session.accessToken,
            'crmid': session.crmid,
            'uniqueid': session.uniqueId,
            'channel_id': effectiveChannelId.toString(),
            if (hdnea.isNotEmpty) 'hdnea': hdnea,
          };
          final queryString = queryParams.entries
              .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
              .join('&');

          final finalStreamUrl = kIsWeb
              ? '${ApiEndpoints.streamProxyUrl}?$queryString'
              : rawStreamUrl;

          return StreamPlaybackInfo(
            streamUrl: finalStreamUrl,
            headers: {
              'User-Agent': 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7',
              'appkey': 'NzNiMDhlYzQyNjJm',
              'ssotoken': session.ssoToken,
              'accesstoken': session.accessToken,
              'crmid': session.crmid,
              'channelId': channel.channelId.toString(),
              'Cookie': 'ssotoken=${session.ssoToken}${hdnea.isNotEmpty ? '; __hdnea__=$hdnea' : ''}',
            },
            isHls: true,
          );
        } else {
          throw Exception('No playable stream URL returned: ${response.body}');
        }
      } else {
        throw Exception('Playback API returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to ${channel.channelName} stream: $e');
    }
  }

  List<ChannelModel> _buildSampleChannels() {
    return [
      ChannelModel(
        channelId: 757,
        channelName: 'Colors Kannada HD',
        logoUrl: '',
        categoryId: 5,
        categoryName: 'Entertainment',
        languageId: 13,
        languageName: 'Kannada',
        isHd: true,
      ),
      ChannelModel(
        channelId: 1632,
        channelName: 'Colors Kannada Cinema',
        logoUrl: '',
        categoryId: 6,
        categoryName: 'Movies',
        languageId: 13,
        languageName: 'Kannada',
        isHd: true,
      ),
      ChannelModel(
        channelId: 619,
        channelName: 'TV9 Kannada',
        logoUrl: '',
        categoryId: 12,
        categoryName: 'News',
        languageId: 13,
        languageName: 'Kannada',
        isHd: true,
      ),
      ChannelModel(
        channelId: 370,
        channelName: 'Suvarna HD',
        logoUrl: '',
        categoryId: 5,
        categoryName: 'Entertainment',
        languageId: 13,
        languageName: 'Kannada',
        isHd: true,
      ),
      ChannelModel(
        channelId: 713,
        channelName: 'DD9 chandana (kannada)',
        logoUrl: '',
        categoryId: 5,
        categoryName: 'Entertainment',
        languageId: 13,
        languageName: 'Kannada',
        isHd: false,
      ),
      ChannelModel(
        channelId: 626,
        channelName: 'Suvarna News',
        logoUrl: '',
        categoryId: 12,
        categoryName: 'News',
        languageId: 13,
        languageName: 'Kannada',
        isHd: true,
      ),
      ChannelModel(
        channelId: 1140,
        channelName: 'Suvarna Plus',
        logoUrl: '',
        categoryId: 6,
        categoryName: 'Movies',
        languageId: 13,
        languageName: 'Kannada',
        isHd: false,
      ),
      ChannelModel(
        channelId: 2742,
        channelName: 'Zee Kannada News',
        logoUrl: '',
        categoryId: 12,
        categoryName: 'News',
        languageId: 13,
        languageName: 'Kannada',
        isHd: true,
      ),
    ];
  }
}

