import 'dart:convert';
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
        final ssoToken = data['ssoToken'] ?? '';
        final sessionAttrs = data['sessionAttributes'] ?? {};
        final userAttrs = sessionAttrs['user'] ?? {};
        final uniqueId = userAttrs['unique'] ?? userAttrs['uniqueId'] ?? '';
        final crmid = userAttrs['subscriberId'] ?? userAttrs['crmid'] ?? '';

        if (ssoToken.isNotEmpty) {
          final session = AuthSession(
            ssoToken: ssoToken,
            uniqueId: uniqueId,
            crmid: crmid,
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
      final response = await http.post(
        Uri.parse(ApiEndpoints.refreshOtpUrl),
        headers: {
          'accesstoken': currentSession.ssoToken,
          'uniqueId': currentSession.uniqueId,
          'devicetype': 'phone',
          'os': 'android',
          'User-Agent': ApiEndpoints.defaultUserAgent,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['ssoToken'] ?? currentSession.ssoToken;
        final updated = AuthSession(
          ssoToken: newToken,
          uniqueId: currentSession.uniqueId,
          crmid: currentSession.crmid,
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

    if (session == null || session.ssoToken.isEmpty) {
      throw Exception('Authentication required. Please log in with your Jio number to stream live TV.');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.playbackBaseUrl),
        headers: {
          'ssotoken': session.ssoToken,
          'channel_id': channel.channelId.toString(),
          'crmid': session.crmid,
          'uniqueId': session.uniqueId,
          'User-Agent': ApiEndpoints.defaultUserAgent,
          'deviceType': 'phone',
          'os': 'android',
          'appkey': ApiEndpoints.appKey,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'stream_type=Live&channel_id=${channel.channelId}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final streamUrl = data['result'] ?? '';
        if (streamUrl.isNotEmpty) {
          return StreamPlaybackInfo(
            streamUrl: streamUrl,
            headers: {
              'User-Agent': ApiEndpoints.defaultUserAgent,
              'Cookie': 'ssotoken=${session.ssoToken}',
            },
            isHls: true,
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to connect to ${channel.channelName} stream: $e');
    }

    throw Exception('Stream unavailable for ${channel.channelName}. Active subscription required.');
  }

  List<ChannelModel> _buildSampleChannels() {
    return [
      ChannelModel(
        channelId: 101,
        channelName: 'Colors Kannada HD',
        logoUrl: '',
        categoryId: 1,
        categoryName: 'Entertainment',
        languageId: 13,
        languageName: 'Kannada',
        isHd: true,
      ),
      ChannelModel(
        channelId: 102,
        channelName: 'Zee Kannada HD',
        logoUrl: '',
        categoryId: 1,
        categoryName: 'Entertainment',
        languageId: 13,
        languageName: 'Kannada',
        isHd: true,
      ),
      ChannelModel(
        channelId: 103,
        channelName: 'Star Suvarna Plus',
        logoUrl: '',
        categoryId: 1,
        categoryName: 'Entertainment',
        languageId: 13,
        languageName: 'Kannada',
        isHd: false,
      ),
      ChannelModel(
        channelId: 104,
        channelName: 'TV9 Kannada Live',
        logoUrl: '',
        categoryId: 7,
        categoryName: 'News',
        languageId: 13,
        languageName: 'Kannada',
        isHd: true,
      ),
      ChannelModel(
        channelId: 105,
        channelName: 'Sports 18 HD',
        logoUrl: '',
        categoryId: 4,
        categoryName: 'Sports',
        languageId: 6,
        languageName: 'English',
        isHd: true,
      ),
      ChannelModel(
        channelId: 106,
        channelName: 'Star Sports 1 Kannada',
        logoUrl: '',
        categoryId: 4,
        categoryName: 'Sports',
        languageId: 13,
        languageName: 'Kannada',
        isHd: true,
      ),
    ];
  }
}

