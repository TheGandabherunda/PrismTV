import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_endpoints.dart';
import '../../core/services/local_stream_proxy.dart';
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

  @override
  void clearCache() {
    _cachedChannels = null;
  }

  /// Clear in-memory channels cache so new subscription plans immediately re-filter the catalog
  void invalidateCache() {
    _cachedChannels = null;
  }

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

    final session = HiveService.getSavedSession();
    final restrictedIds = HiveService.getRestrictedChannelIds();

    debugPrint('[JIO_CHANNELS] Fetching channels. Session valid: ${session?.isValid}, Mobile: ${session?.mobileNumber}');
    debugPrint('[JIO_CHANNELS] Active Base Plan: ${session?.hasActiveJioBase}, Active Premium: ${session?.hasActivePremium}');

    http.Response? response;
    try {
      response = await http.get(
        Uri.parse(ApiEndpoints.channelListUrl),
        headers: {
          'User-Agent': ApiEndpoints.defaultUserAgent,
        },
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[JIO_CHANNELS] Primary v3.1 fetch failed: $e. Trying fallback...');
    }

    // Fallback to v1.4 if primary was unavailable
    if (response == null || response.statusCode != 200) {
      try {
        response = await http.get(
          Uri.parse(ApiEndpoints.fallbackChannelListUrl),
          headers: {'User-Agent': ApiEndpoints.defaultUserAgent},
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('[JIO_CHANNELS] Fallback fetch failed: $e');
      }
    }

    try {
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['result'] ?? [];
        final favs = HiveService.getFavoriteChannelIds();

        final channels = list.map((item) {
          final model = ChannelModel.fromJson(item as Map<String, dynamic>);
          model.isFavorite = favs.contains(model.channelId);
          if (model.channelId == 3585) {
            return ChannelModel(
              channelId: 3585,
              channelName: 'Sony LIV Sports Ten 4 Kannada HD',
              logoUrl: model.logoUrl,
              categoryId: model.categoryId,
              categoryName: model.categoryName,
              languageId: model.languageId,
              languageName: model.languageName,
              isHd: true,
              isCatchupAvailable: model.isCatchupAvailable,
              isPremium: true,
              planType: 'premium',
              businessType: 'premium',
              packageIds: const ['1', '6', '7', '23'],
              channelPrice: model.channelPrice,
              isFavorite: model.isFavorite,
            );
          }
          return model;
        }).toList();

        debugPrint('[JIO_CHANNELS] Total raw fetched: ${channels.length}');

        // Deduplicate duplicate SD channel aliases (e.g. Colors Kannada SD, Colors SD, Colors Marathi SD, etc.)
        final sdDuplicateIds = {1368, 1369, 1370, 1325, 1326};
        // Remove dead / inactive PayWall event placeholders (which return 404 on Jio CDN)
        final deadPaywallIds = {3528, 3397, 3398, 3374, 3376};
        channels.removeWhere((c) {
          if (sdDuplicateIds.contains(c.channelId)) return true;
          if (deadPaywallIds.contains(c.channelId)) return true;
          // Filter out internal JioFiber STB multicast feeds (not playable on mobile/OTT)
          final nameUpper = c.channelName.toUpperCase().trim();
          if (nameUpper.endsWith(' STB') || nameUpper.contains(' STB ') || nameUpper.endsWith('_STB')) {
            return true;
          }
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

        // =======================================================================
        // STRONG SUBSCRIPTION FILTER ACROSS ALL PLATFORMS:
        // Only keep channels that the logged-in mobile number has a subscription for!
        // =======================================================================
        final beforeFilterCount = channels.length;
        channels.removeWhere((c) => !c.isSubscribedFor(session, restrictedIds: restrictedIds));
        debugPrint('[JIO_SUBSCRIPTION_FILTER] Kept ${channels.length} of $beforeFilterCount subscribed channels for ${session?.mobileNumber ?? "Guest"}');

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
    } catch (e, st) {
      debugPrint('[JIO_CHANNELS_ERR] $e\n$st');
    }

    return _buildSampleChannels();
  }

  final Map<int, (DateTime, List<EpgProgramModel>)> _epgCache = {};

  @override
  Future<List<EpgProgramModel>> fetchEpg(int channelId) async {
    final now = DateTime.now();
    final cached = _epgCache[channelId];
    if (cached != null && now.difference(cached.$1).inMinutes < 15) {
      return cached.$2;
    }

    try {
      final uri = Uri.parse('${ApiEndpoints.epgUrl}?offset=0&channel_id=$channelId');
      final response = await http.get(
        uri,
        headers: {'User-Agent': ApiEndpoints.defaultUserAgent},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['epg'] ?? [];
        final parsed = list
            .map((item) => EpgProgramModel.fromJson(item as Map<String, dynamic>))
            .toList();
        if (parsed.isNotEmpty) {
          _epgCache[channelId] = (now, parsed);
          return parsed;
        }
      }
    } catch (_) {}

    // Fallback EPG entry
    final fallbackStart = now.subtract(const Duration(minutes: 15));
    final fallbackEnd = now.add(const Duration(minutes: 45));
    return [
      EpgProgramModel(
        showName: 'Live Broadcast',
        description: 'Now streaming on PrismTV live broadcast network.',
        startTime: fallbackStart,
        endTime: fallbackEnd,
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

      int effectiveChannelId = channel.channelId;
      // Auto-route paywalled / inactive Sony LIV event pop-up aliases to their active 24/7 live broadcast feeds
      if (effectiveChannelId == 3528) {
        // Sony Liv Sports 4 Kannada -> Sony Sports Ten 4 Kannada
        effectiveChannelId = 3585;
      } else if (effectiveChannelId == 3397) {
        // Sony LIV Sports 4 Tamil -> Sony Ten 4 Tamil
        effectiveChannelId = 1774;
      } else if (effectiveChannelId == 3398) {
        // Sony LIV Sports 4 Telugu -> Sony Ten 4 Telugu
        effectiveChannelId = 1775;
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

      var response = await http.post(
        Uri.parse(ApiEndpoints.playbackBaseUrl),
        headers: requestHeaders,
        body: formBody,
      );

      // Automatic token refresh if session expired (419 / 401)
      if ((response.statusCode == 419 || response.statusCode == 401) && session.ssoToken.isNotEmpty) {
        debugPrint('[JIO_STREAM] Playback returned ${response.statusCode}. Refreshing SSO token...');
        final refreshed = await refreshSession(session);
        if (refreshed != null && refreshed.ssoToken != session.ssoToken) {
          requestHeaders['accessToken'] = refreshed.accessToken;
          requestHeaders['accesstoken'] = refreshed.accessToken;
          requestHeaders['ssoToken'] = refreshed.ssoToken;
          requestHeaders['ssotoken'] = refreshed.ssoToken;
          response = await http.post(
            Uri.parse(ApiEndpoints.playbackBaseUrl),
            headers: requestHeaders,
            body: formBody,
          );
        }
      }

      if (response.statusCode == 403) {
        await HiveService.addRestrictedChannelId(effectiveChannelId);
        _cachedChannels?.removeWhere((c) => c.channelId == effectiveChannelId);
        throw Exception('This channel is not included in your Jio number\'s subscription plan.');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bitrates = data['bitrates'] as Map<String, dynamic>?;
        final mpd = data['mpd'] as Map<String, dynamic>?;

        // MPEG-DASH (Widevine DRM) contains the authentic 1080p full HD studio broadcasts
        // (1920x1080 at 2.3+ Mbps AVC High Profile), whereas HLS mobile feeds are capped by Jio at 360p.
        String rawStreamUrl = '';
        String drmLicenseUrl = '';
        String hlsFallbackUrl = '';

        // Extract HLS stream URL from result or bitrates for fallback/native
        hlsFallbackUrl = (data['result'] as String?) ?? '';
        if (hlsFallbackUrl.isEmpty && bitrates != null) {
          hlsFallbackUrl = (bitrates['auto'] as String?) ?? (bitrates['high'] as String?) ?? '';
        }

        if (kIsWeb) {
          // On Web, Shaka Player natively decrypts Widevine MPEG-DASH for authentic 1080p Full HD broadcast
          if (mpd != null) {
            final mpdBitrates = mpd['bitrates'] as Map<String, dynamic>?;
            // Prefer mpd.result (minrate=80000) which contains ALL representations from 180p up to 1080p,
            // preventing Broadpeak packager from stripping video on SD channels. Shaka ABR automatically
            // selects 1080p Full HD for HD channels via defaultBandwidthEstimate. Fallback to bitrates.
            final autoMpd = mpdBitrates != null ? (mpdBitrates['auto'] as String? ?? mpdBitrates['high'] as String?) : null;
            rawStreamUrl = (mpd['result'] as String?) ?? autoMpd ?? '';
            drmLicenseUrl = (mpd['key'] as String?) ?? '';
          }
          if (rawStreamUrl.isEmpty) {
            rawStreamUrl = hlsFallbackUrl;
          }
        } else {
          // On Native Android TV / Mobile, prefer Widevine MPEG-DASH for authentic 1080p Full HD studio broadcast.
          // Jio caps mobile HLS fallback at 360p or 480p, while WDVLive MPEG-DASH contains
          // full 1080p (1920x1080 @ 2.3+ Mbps AVC High Profile) studio broadcasts.
          if (mpd != null) {
            final mpdBitrates = mpd['bitrates'] as Map<String, dynamic>?;
            final autoMpd = mpdBitrates != null ? (mpdBitrates['auto'] as String? ?? mpdBitrates['high'] as String?) : null;
            rawStreamUrl = (mpd['result'] as String?) ?? autoMpd ?? '';
            drmLicenseUrl = (mpd['key'] as String?) ?? '';
          }
          if (rawStreamUrl.isEmpty) {
            rawStreamUrl = hlsFallbackUrl;
          }
        }

        if (rawStreamUrl.isNotEmpty) {
          // Extract hdnea if present anywhere (query params, enclosing URL, or response data)
          String hdnea = '';
          final hdneaRegex = RegExp(r'(?:__hdnea__|hdnea)=([^&]+)');
          final match = hdneaRegex.firstMatch(rawStreamUrl) ??
              hdneaRegex.firstMatch(hlsFallbackUrl) ??
              (data['result'] != null ? hdneaRegex.firstMatch(data['result'].toString()) : null);
          if (match != null && match.group(1) != null) {
            hdnea = match.group(1)!;
          }
          if (hdnea.isEmpty && data['token'] != null) {
            hdnea = data['token'].toString().trim();
          }

          if (hdnea.isNotEmpty && !rawStreamUrl.contains('__hdnea__=') && !rawStreamUrl.contains('hdnea=')) {
            final sep = rawStreamUrl.contains('?') ? '&' : '?';
            rawStreamUrl = '$rawStreamUrl${sep}__hdnea__=$hdnea';
          }

          // Detect PayWall event stream placeholders
          if (rawStreamUrl.toLowerCase().contains('paywall')) {
            await HiveService.addRestrictedChannelId(effectiveChannelId);
            _cachedChannels?.removeWhere((c) => c.channelId == effectiveChannelId);
            throw Exception('This channel requires a premium add-on subscription for your Jio number.');
          }

          // Follow 302/301 redirects natively so ExoPlayer does not lose Cookie / User-Agent headers
          if (!kIsWeb && rawStreamUrl.isNotEmpty) {
            try {
              final headReq = http.Request('HEAD', Uri.parse(rawStreamUrl))
                ..followRedirects = false
                ..headers['User-Agent'] = 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7';
              if (hdnea.isNotEmpty) {
                headReq.headers['Cookie'] = '__hdnea__=$hdnea; ssotoken=${session.ssoToken}';
              }
              final headRes = await headReq.send();
              if (headRes.statusCode >= 300 && headRes.statusCode < 400 && headRes.headers['location'] != null) {
                final loc = headRes.headers['location']!;
                rawStreamUrl = Uri.parse(rawStreamUrl).resolve(loc).toString();
                debugPrint('[JIO_STREAM] Resolved 302 redirect to: $rawStreamUrl');
                final redirMatch = hdneaRegex.firstMatch(rawStreamUrl);
                if (redirMatch != null && redirMatch.group(1) != null) {
                  hdnea = redirMatch.group(1)!;
                }
              }
            } catch (e) {
              debugPrint('[JIO_STREAM_REDIRECT_ERR] $e');
            }
          }

          debugPrint('[JIO_STREAM] ch=${channel.channelId} hasHdnea=${hdnea.isNotEmpty} url=$rawStreamUrl');

          // Validate playlist availability in Dart before handing to ExoPlayer
          if (!kIsWeb && rawStreamUrl.isNotEmpty) {
            try {
              final testPlRes = await http.get(Uri.parse(rawStreamUrl), headers: {
                'User-Agent': 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7',
                if (hdnea.isNotEmpty) 'Cookie': '__hdnea__=$hdnea; ssotoken=${session.ssoToken}',
              });
              debugPrint('[JIO_PLAYLIST_DART] status=${testPlRes.statusCode} length=${testPlRes.body.length}');
              if (testPlRes.statusCode == 404) {
                if (rawStreamUrl.contains('.mpd') && hlsFallbackUrl.isNotEmpty && hlsFallbackUrl != rawStreamUrl) {
                  debugPrint('[JIO_PLAYLIST_DART] MPD 404, falling back to HLS...');
                  rawStreamUrl = hlsFallbackUrl;
                  drmLicenseUrl = '';
                } else if (mpd != null && (mpd['key'] != null || mpd['result'] != null)) {
                  throw Exception('Channel restricted: Broadcaster requires Widevine DRM (unavailable on mobile HLS).');
                } else {
                  throw Exception('Broadcast stream is temporarily unavailable on Jio CDN servers.');
                }
              } else if (testPlRes.statusCode == 403) {
                await HiveService.addRestrictedChannelId(effectiveChannelId);
                _cachedChannels?.removeWhere((c) => c.channelId == effectiveChannelId);
                throw Exception('Channel access restricted by broadcaster on your Jio plan.');
              }
            } catch (e) {
              if (e.toString().contains('Exception:')) rethrow;
              debugPrint('[JIO_PLAYLIST_DART_ERR] $e');
            }
          }

          // Build proxied HLS fallback URL if DASH stream has missing video/audio
          String proxiedHlsFallback = '';
          if (hlsFallbackUrl.isNotEmpty && kIsWeb) {
            final hlsMatch = hdneaRegex.firstMatch(hlsFallbackUrl);
            final hlsHdnea = hlsMatch?.group(1) ?? hdnea;
            final hlsParams = <String, String>{
              'url': hlsFallbackUrl,
              'channel_id': effectiveChannelId.toString(),
              if (hlsHdnea.isNotEmpty) 'hdnea': hlsHdnea,
              'lang': channel.languageCode,
            };
            final hlsQuery = hlsParams.entries
                .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
                .join('&');
            proxiedHlsFallback = '${ApiEndpoints.streamProxyUrl}?$hlsQuery';
          }

          // On Web, route through local stream proxy to bypass browser CORS and deliver authentication
          final queryParams = <String, String>{
            'url': rawStreamUrl,
            if (drmLicenseUrl.isNotEmpty) 'drm_key': drmLicenseUrl,
            'ssotoken': session.ssoToken,
            'accesstoken': session.accessToken,
            'crmid': session.crmid,
            'uniqueid': session.uniqueId,
            'channel_id': effectiveChannelId.toString(),
            if (hdnea.isNotEmpty) 'hdnea': hdnea,
            if (proxiedHlsFallback.isNotEmpty) 'hls_fallback': proxiedHlsFallback,
            'lang': channel.languageCode,
          };
          final queryString = queryParams.entries
              .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
              .join('&');

          final isDASH = rawStreamUrl.contains('.mpd');

          final finalStreamUrl = kIsWeb
              ? '${ApiEndpoints.streamProxyUrl}?$queryString'
              : (isDASH
                  ? LocalStreamProxy.getProxiedMpdUrl(rawStreamUrl, hdnea: hdnea, channelId: effectiveChannelId)
                  : LocalStreamProxy.getProxiedUrl(rawStreamUrl, hdnea: hdnea, channelId: effectiveChannelId));

          return StreamPlaybackInfo(
            streamUrl: finalStreamUrl,
            headers: {
              'User-Agent': 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7',
              'appkey': 'NzNiMDhlYzQyNjJm',
              'ssotoken': session.ssoToken,
              'accesstoken': session.accessToken,
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
              'srno': srnoStr,
              'usergroup': 'tvYR7NSNn7rymo3F',
              'channelId': effectiveChannelId.toString(),
              'Cookie': hdnea.isNotEmpty
                  ? '__hdnea__=$hdnea; ssotoken=${session.ssoToken}'
                  : 'ssotoken=${session.ssoToken}',
              if (drmLicenseUrl.isNotEmpty)
                'X-Drm-License-Url': LocalStreamProxy.getDrmLicenseUrl(drmLicenseUrl, channelId: effectiveChannelId),
            },
            isHls: !isDASH,
            licenseUrl: drmLicenseUrl.isNotEmpty ? drmLicenseUrl : null,
          );
        } else {
          throw Exception('No playable stream URL returned for this channel.');
        }
      } else if (response.statusCode == 403) {
        final bodyStr = response.body;
        if (bodyStr.contains('No eligible plans') || bodyStr.contains('Forbidden')) {
          throw Exception('Subscription required: Broadcaster requires an add-on plan on your Jio account.');
        }
        throw Exception('Broadcaster restricted: 403 Forbidden.');
      } else if (response.statusCode == 404) {
        throw Exception('Channel feed is currently offline or discontinued by broadcaster.');
      } else {
        throw Exception('Broadcaster error (${response.statusCode}). Please try another channel.');
      }
    } catch (e) {
      final cleanMsg = e.toString().replaceAll('Exception: ', '').trim();
      throw Exception(cleanMsg);
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

