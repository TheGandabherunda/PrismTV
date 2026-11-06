import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_endpoints.dart';
import '../../core/storage/hive_service.dart';

/// In-app loopback HTTP streaming proxy for Android TV and Android Mobile.
/// Binds exclusively to 127.0.0.1 on an ephemeral port.
/// Proxies HLS manifests, MPEG-DASH (1080p Full HD) manifests, AES-128 keys, and Widevine DRM challenges,
/// with automatic background HDNEA token refresh ensuring uninterrupted 24/7 top-notch streaming.
class LocalStreamProxy {
  static HttpServer? _server;
  static int _port = 0;
  static final Map<String, List<int>> _keyCache = {};

  // Separate token caches for DASH (Widevine 1080p studio streams) and HLS (m3u8 fallback)
  static final Map<int, String> _channelDashHdnea = {};
  static final Map<int, DateTime> _channelDashFetchTime = {};
  static final Map<int, String> _channelHlsHdnea = {};
  static final Map<int, DateTime> _channelHlsFetchTime = {};

  static final Map<int, String> _channelDashBase = {};
  static String _lastDashBase = '';

  // Track active stream context so any relative child requests from ExoPlayer resolve properly
  static Uri? _lastBaseUri;
  static String _lastDashHdnea = '';
  static String _lastHlsHdnea = '';
  static int? _lastChannelId;
  static bool _lastIsDash = true;

  static int get port => _port;

  static Future<void> ensureStarted() async {
    if (_server != null) return;

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      debugPrint('[LOCAL_STREAM_PROXY] Started on 127.0.0.1:$_port');

      _server!.listen(
        _handleRequest,
        onError: (err) => debugPrint('[LOCAL_STREAM_PROXY_ERR] $err'),
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[LOCAL_STREAM_PROXY_INIT_ERR] $e');
    }
  }

  static String getProxiedUrl(String rawStreamUrl, {String? hdnea, int? channelId}) {
    if (rawStreamUrl.isEmpty) return rawStreamUrl;
    if (_port == 0) return rawStreamUrl;

    if (channelId != null && hdnea != null && hdnea.isNotEmpty) {
      _channelHlsHdnea[channelId] = hdnea;
      _channelHlsFetchTime[channelId] = DateTime.now();
      _lastHlsHdnea = hdnea;
    }
    _lastChannelId = channelId;
    _lastIsDash = false;

    final token = hdnea ?? (_lastHlsHdnea.isNotEmpty ? _lastHlsHdnea : '');
    final tokenParam = token.isNotEmpty ? '&hdnea=${Uri.encodeComponent(token)}' : '';
    final chParam = channelId != null ? '&ch=$channelId' : '';
    return 'http://127.0.0.1:$_port/manifest.m3u8?url=${Uri.encodeComponent(rawStreamUrl)}$tokenParam$chParam';
  }

  static String getProxiedMpdUrl(String rawStreamUrl, {String? hdnea, int? channelId}) {
    if (rawStreamUrl.isEmpty) return rawStreamUrl;
    if (_port == 0) return rawStreamUrl;

    if (channelId != null && hdnea != null && hdnea.isNotEmpty) {
      _channelDashHdnea[channelId] = hdnea;
      _channelDashFetchTime[channelId] = DateTime.now();
      _lastDashHdnea = hdnea;
    }
    _lastChannelId = channelId;
    _lastIsDash = true;

    final token = hdnea ?? (_lastDashHdnea.isNotEmpty ? _lastDashHdnea : '');
    final tokenParam = token.isNotEmpty ? '&hdnea=${Uri.encodeComponent(token)}' : '';
    final chParam = channelId != null ? '&ch=$channelId' : '';
    return 'http://127.0.0.1:$_port/manifest.mpd?url=${Uri.encodeComponent(rawStreamUrl)}$tokenParam$chParam';
  }

  static String getDrmLicenseUrl(String originalLicenseUrl, {int? channelId}) {
    if (originalLicenseUrl.isEmpty) return originalLicenseUrl;
    if (_port == 0) return originalLicenseUrl;

    final chParam = channelId != null ? '&ch=$channelId' : '';
    return 'http://127.0.0.1:$_port/drm?url=${Uri.encodeComponent(originalLicenseUrl)}$chParam';
  }

  static String _generateDateTime() {
    final d = DateTime.now().toUtc();
    String pad(int n, [int l = 2]) => n.toString().padLeft(l, '0');
    final yy = pad(d.year % 100);
    final mm = pad(d.month);
    final dd = pad(d.day);
    final hh = pad(d.hour);
    final mi = pad(d.minute);
    final ms = pad(d.millisecond, 3);
    return '$yy$mm$dd$hh$mi$ms';
  }

  // Deduplication map to avoid duplicate concurrent HTTP refreshes for the same channel
  static final Map<String, Future<String?>> _inFlightRefreshes = {};

  /// Automatically refresh the __hdnea__ token for a channel directly with Jio's playback API.
  /// When isDash == true, extracts specifically the Widevine DASH token with WDVLive/* ACL.
  /// When isDash == false, extracts specifically the HLS token with Fallback/* or HLS/* ACL.
  static Future<String?> refreshHdnea(int channelId, {bool isDash = true}) async {
    final key = '$channelId-${isDash ? 'dash' : 'hls'}';
    if (_inFlightRefreshes.containsKey(key)) {
      return _inFlightRefreshes[key];
    }

    final future = _doRefreshHdnea(channelId, isDash: isDash);
    _inFlightRefreshes[key] = future;
    try {
      final res = await future;
      return res;
    } finally {
      _inFlightRefreshes.remove(key);
    }
  }

  static Future<String?> _doRefreshHdnea(int channelId, {bool isDash = true}) async {
    try {
      final session = HiveService.getSavedSession();
      if (session == null || !session.isValid) {
        debugPrint('[LOCAL_STREAM_PROXY] Cannot refresh token: No active session');
        return null;
      }

      final now = DateTime.now().toUtc();
      String pad(int n) => n.toString().padLeft(2, '0');
      final beginStr = '${now.year}${pad(now.month)}${pad(now.day)}T${pad(now.hour)}${pad(now.minute)}${pad(now.second)}';
      final srnoStr = '${now.year}${pad(now.month)}${pad(now.day)}';

      int effectiveChannelId = channelId;
      if (effectiveChannelId == 3528) {
        effectiveChannelId = 3585;
      } else if (effectiveChannelId == 3397) {
        effectiveChannelId = 1774;
      } else if (effectiveChannelId == 3398) {
        effectiveChannelId = 1775;
      }

      final formBody = 'channel_id=$effectiveChannelId&stream_type=Seek&begin=$beginStr&srno=$srnoStr';

      debugPrint('[LOCAL_STREAM_PROXY] Refreshing ${isDash ? "DASH (1080p)" : "HLS"} token for channel $effectiveChannelId...');
      final res = await http.post(
        Uri.parse(ApiEndpoints.playbackBaseUrl),
        headers: {
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
        },
        body: formBody,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // 1. Extract authentic DASH Widevine token specifically (ACL includes WDVLive/*)
        final mpd = data['mpd'] as Map<String, dynamic>?;
        if (mpd != null) {
          final mpdUrl = (mpd['result'] as String?) ??
              ((mpd['bitrates'] as Map?)?['auto'] as String?) ??
              ((mpd['bitrates'] as Map?)?['high'] as String?) ?? '';
          final match = RegExp(r'(?:__hdnea__|hdnea)=([^&]+)').firstMatch(mpdUrl);
          if (match != null && match.group(1) != null) {
            final dashToken = match.group(1)!;
            _channelDashHdnea[channelId] = dashToken;
            _channelDashFetchTime[channelId] = DateTime.now();
            _lastDashHdnea = dashToken;
            debugPrint('[LOCAL_STREAM_PROXY] Successfully refreshed DASH HDNEA token for channel $channelId');
          }
        }

        // 2. Extract authentic HLS token specifically (ACL includes Fallback/* or HLS/*)
        final hlsUrl = (data['result'] as String?) ??
            ((data['bitrates'] as Map?)?['auto'] as String?) ??
            ((data['bitrates'] as Map?)?['high'] as String?) ?? '';
        final hlsMatch = RegExp(r'(?:__hdnea__|hdnea)=([^&]+)').firstMatch(hlsUrl);
        if (hlsMatch != null && hlsMatch.group(1) != null) {
          final hlsToken = hlsMatch.group(1)!;
          _channelHlsHdnea[channelId] = hlsToken;
          _channelHlsFetchTime[channelId] = DateTime.now();
          _lastHlsHdnea = hlsToken;
          debugPrint('[LOCAL_STREAM_PROXY] Successfully refreshed HLS HDNEA token for channel $channelId');
        }

        return isDash ? _channelDashHdnea[channelId] : _channelHlsHdnea[channelId];
      } else {
        debugPrint('[LOCAL_STREAM_PROXY] Refresh failed with status: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('[LOCAL_STREAM_PROXY_REFRESH_ERR] $e');
    }
    return null;
  }

  static Future<void> _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path;
      final query = request.uri.queryParameters;

      if (path == '/manifest.m3u8') {
        await _handleManifest(request, query);
        return;
      }

      if (path == '/manifest.mpd') {
        await _handleMpd(request, query);
        return;
      }

      if (path == '/drm') {
        await _handleDrm(request, query);
        return;
      }

      if (path == '/key') {
        await _handleKey(request, query);
        return;
      }

      // Handle DASH segment redirects: /dash/<channelId>/<segmentName> or /dash/?base=...
      if (path.startsWith('/dash/')) {
        final afterDash = path.substring('/dash/'.length);
        final slashIdx = afterDash.indexOf('/');
        int? channelId;
        String segName = '';
        if (slashIdx != -1) {
          channelId = int.tryParse(afterDash.substring(0, slashIdx));
          segName = afterDash.substring(slashIdx + 1);
        } else {
          segName = afterDash;
        }

        if (channelId == null || channelId == 0) {
          final chQuery = query['ch'];
          channelId = chQuery != null ? int.tryParse(chQuery) : _lastChannelId;
        }

        if (segName.isEmpty) {
          segName = query['segment'] ?? '';
        }

        // Check if DASH token is nearing expiration (> 75 seconds old)
        if (channelId != null) {
          final fetchTime = _channelDashFetchTime[channelId];
          if (fetchTime != null && DateTime.now().difference(fetchTime).inSeconds > 75) {
            refreshHdnea(channelId, isDash: true);
          }
        }

        final base = query['base'] ??
            (channelId != null ? _channelDashBase[channelId] : null) ??
            _lastDashBase;
        final activeToken = (channelId != null ? _channelDashHdnea[channelId] : null) ?? _lastDashHdnea;
        final cleanBase = base.endsWith('/') ? base : '$base/';
        final target = '$cleanBase$segName?__hdnea__=$activeToken';

        request.response.statusCode = HttpStatus.found;
        request.response.headers.set('Location', target);
        request.response.headers.set('Access-Control-Allow-Origin', '*');
        await request.response.close();
        return;
      }

      // Handle relative paths that ExoPlayer resolves against http://127.0.0.1:$port/...
      if (_lastBaseUri != null) {
        final relPath = path.startsWith('/') ? path.substring(1) : path;
        final resolvedUri = _lastBaseUri!.resolve(relPath);
        var forwardUrl = resolvedUri.toString();

        final activeToken = _lastIsDash
            ? ((_lastChannelId != null ? _channelDashHdnea[_lastChannelId!] : null) ?? _lastDashHdnea)
            : ((_lastChannelId != null ? _channelHlsHdnea[_lastChannelId!] : null) ?? _lastHlsHdnea);
        if (activeToken.isNotEmpty && !forwardUrl.contains('__hdnea__=')) {
          forwardUrl += '${forwardUrl.contains('?') ? '&' : '?'}__hdnea__=$activeToken';
        }

        debugPrint('[LOCAL_STREAM_PROXY_RESOLVE] $path -> $forwardUrl');

        if (path.endsWith('.m3u8') || path.contains('.m3u8')) {
          await _handleManifest(request, {
            'url': forwardUrl,
            'hdnea': activeToken,
            if (_lastChannelId != null) 'ch': _lastChannelId.toString(),
          });
          return;
        }

        if (path.contains('.key') || path.contains('.pkey') || path.contains('aes128')) {
          await _handleKey(request, {
            'url': forwardUrl,
            if (_lastChannelId != null) 'ch': _lastChannelId.toString(),
          });
          return;
        }

        // Direct redirect (302) for video/audio segments to CDN with active token
        request.response.statusCode = HttpStatus.found;
        request.response.headers.set('Location', forwardUrl);
        request.response.headers.set('Access-Control-Allow-Origin', '*');
        await request.response.close();
        return;
      }

      debugPrint('[LOCAL_STREAM_PROXY_404] Unhandled path: $path');
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('Not Found');
      await request.response.close();
    } catch (e) {
      debugPrint('[LOCAL_STREAM_PROXY_REQ_ERR] $e');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Internal Server Error: $e');
        await request.response.close();
      } catch (_) {}
    }
  }

  static Future<void> _handleManifest(HttpRequest request, Map<String, String> query) async {
    final targetUrl = query['url'] ?? '';
    var token = query['hdnea'] ?? '';
    final chStr = query['ch'];
    final channelId = chStr != null ? int.tryParse(chStr) : null;

    if (targetUrl.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Missing url parameter');
      await request.response.close();
      return;
    }

    if (channelId != null) {
      _lastChannelId = channelId;
      _lastIsDash = false;
      if (_channelHlsHdnea.containsKey(channelId)) {
        token = _channelHlsHdnea[channelId]!;
      }
      final fetchTime = _channelHlsFetchTime[channelId];
      if (fetchTime != null && DateTime.now().difference(fetchTime).inSeconds > 75) {
        final fresh = await refreshHdnea(channelId, isDash: false);
        if (fresh != null) token = fresh;
      }
    }

    var fetchUrl = targetUrl;
    if (token.isNotEmpty) {
      if (fetchUrl.contains('__hdnea__=')) {
        fetchUrl = fetchUrl.replaceAll(RegExp(r'__hdnea__=[^&]+'), '__hdnea__=$token');
      } else {
        fetchUrl += '${fetchUrl.contains('?') ? '&' : '?'}__hdnea__=$token';
      }
    }

    var upstreamRes = await http.get(Uri.parse(fetchUrl), headers: {
      'User-Agent': 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7',
      if (token.isNotEmpty) 'Cookie': '__hdnea__=$token',
    });

    if (upstreamRes.statusCode == HttpStatus.forbidden && channelId != null) {
      debugPrint('[LOCAL_STREAM_PROXY] Upstream 403 for $fetchUrl. Triggering immediate HLS HDNEA refresh for ch=$channelId...');
      final freshToken = await refreshHdnea(channelId, isDash: false);
      if (freshToken != null && freshToken != token) {
        token = freshToken;
        fetchUrl = fetchUrl.replaceAll(RegExp(r'__hdnea__=[^&]+'), '__hdnea__=$token');
        upstreamRes = await http.get(Uri.parse(fetchUrl), headers: {
          'User-Agent': 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7',
          'Cookie': '__hdnea__=$token',
        });
      }
    }

    if (upstreamRes.statusCode != HttpStatus.ok) {
      debugPrint('[LOCAL_STREAM_PROXY_MANIFEST_FAIL] Status ${upstreamRes.statusCode} for $fetchUrl');
      request.response.statusCode = upstreamRes.statusCode;
      request.response.write(upstreamRes.body);
      await request.response.close();
      return;
    }

    final baseUri = Uri.parse(targetUrl);
    _lastBaseUri = baseUri;
    _lastHlsHdnea = token;

    final cdnHost = baseUri.host;
    final lines = upstreamRes.body.split('\n');
    final outputLines = <String>[];
    final chParam = channelId != null ? '&ch=$channelId' : '';

    for (var line in lines) {
      var trimmed = line.trim();
      if (trimmed.isEmpty) {
        outputLines.add(line);
        continue;
      }

      if (trimmed.startsWith('#')) {
        // Rewrite AES-128 key directive
        if (trimmed.startsWith('#EXT-X-KEY:') && trimmed.contains('URI="')) {
          final keyMatch = RegExp(r'URI="([^"]+)"').firstMatch(trimmed);
          if (keyMatch != null) {
            final origKeyUri = keyMatch.group(1)!;
            var fixedKeyUri = origKeyUri.replaceFirst(
              RegExp(r'https?://[^/]+/(?:fallback/)?bpk-tv/'),
              'https://$cdnHost/bpk-tv/',
            );
            if (token.isNotEmpty && !fixedKeyUri.contains('__hdnea__=')) {
              fixedKeyUri += '${fixedKeyUri.contains('?') ? '&' : '?'}__hdnea__=$token';
            }
            final proxyKeyUrl = 'http://127.0.0.1:$_port/key?url=${Uri.encodeComponent(fixedKeyUri)}$chParam';
            trimmed = trimmed.replaceFirst('URI="$origKeyUri"', 'URI="$proxyKeyUrl"');
          }
        } else if (trimmed.contains('URI="')) {
          final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(trimmed);
          if (uriMatch != null) {
            final relUri = uriMatch.group(1)!;
            final fullUri = baseUri.resolve(relUri).toString();
            final proxiedChild = 'http://127.0.0.1:$_port/manifest.m3u8?url=${Uri.encodeComponent(fullUri)}${token.isNotEmpty ? '&hdnea=${Uri.encodeComponent(token)}' : ''}$chParam';
            trimmed = trimmed.replaceFirst('URI="$relUri"', 'URI="$proxiedChild"');
          }
        }
        outputLines.add(trimmed);
      } else {
        if (trimmed.endsWith('.m3u8') || trimmed.contains('.m3u8?')) {
          final fullVariantUri = baseUri.resolve(trimmed).toString();
          final proxiedChild = 'http://127.0.0.1:$_port/manifest.m3u8?url=${Uri.encodeComponent(fullVariantUri)}${token.isNotEmpty ? '&hdnea=${Uri.encodeComponent(token)}' : ''}$chParam';
          outputLines.add(proxiedChild);
        } else {
          var fullSegmentUri = baseUri.resolve(trimmed).toString();
          if (token.isNotEmpty) {
            if (fullSegmentUri.contains('__hdnea__=')) {
              fullSegmentUri = fullSegmentUri.replaceAll(RegExp(r'__hdnea__=[^&]+'), '__hdnea__=$token');
            } else {
              fullSegmentUri += '${fullSegmentUri.contains('?') ? '&' : '?'}__hdnea__=$token';
            }
          }
          outputLines.add(fullSegmentUri);
        }
      }
    }

    final responseBody = outputLines.join('\n');
    request.response.headers.contentType = ContentType('application', 'vnd.apple.mpegurl');
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.headers.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    request.response.headers.set('Cache-Control', 'no-cache, no-store');
    request.response.write(responseBody);
    await request.response.close();
  }

  static Future<void> _handleMpd(HttpRequest request, Map<String, String> query) async {
    final targetUrl = query['url'] ?? '';
    var token = query['hdnea'] ?? '';
    final chStr = query['ch'];
    final channelId = chStr != null ? int.tryParse(chStr) : null;

    if (targetUrl.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Missing url parameter');
      await request.response.close();
      return;
    }

    if (channelId != null) {
      _lastChannelId = channelId;
      _lastIsDash = true;
      if (_channelDashHdnea.containsKey(channelId)) {
        token = _channelDashHdnea[channelId]!;
      }
      final fetchTime = _channelDashFetchTime[channelId];
      if (fetchTime != null && DateTime.now().difference(fetchTime).inSeconds > 75) {
        final fresh = await refreshHdnea(channelId, isDash: true);
        if (fresh != null) token = fresh;
      }
    }

    var fetchUrl = targetUrl;
    if (token.isNotEmpty) {
      if (fetchUrl.contains('__hdnea__=')) {
        fetchUrl = fetchUrl.replaceAll(RegExp(r'__hdnea__=[^&]+'), '__hdnea__=$token');
      } else {
        fetchUrl += '${fetchUrl.contains('?') ? '&' : '?'}__hdnea__=$token';
      }
    }

    var upstreamRes = await http.get(Uri.parse(fetchUrl), headers: {
      'User-Agent': 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7',
      if (token.isNotEmpty) 'Cookie': '__hdnea__=$token',
    });

    if (upstreamRes.statusCode == HttpStatus.forbidden && channelId != null) {
      debugPrint('[LOCAL_STREAM_PROXY] MPD returned 403. Refreshing DASH token for ch=$channelId...');
      final freshToken = await refreshHdnea(channelId, isDash: true);
      if (freshToken != null && freshToken != token) {
        token = freshToken;
        fetchUrl = fetchUrl.replaceAll(RegExp(r'__hdnea__=[^&]+'), '__hdnea__=$token');
        upstreamRes = await http.get(Uri.parse(fetchUrl), headers: {
          'User-Agent': 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7',
          'Cookie': '__hdnea__=$token',
        });
      }
    }

    if (upstreamRes.statusCode != HttpStatus.ok) {
      debugPrint('[LOCAL_STREAM_PROXY_MPD_FAIL] Status ${upstreamRes.statusCode} for $fetchUrl');
      request.response.statusCode = upstreamRes.statusCode;
      request.response.write(upstreamRes.body);
      await request.response.close();
      return;
    }

    final baseUri = Uri.parse(targetUrl);
    _lastBaseUri = baseUri;
    _lastDashHdnea = token;

    var body = upstreamRes.body;
    final cdnHost = baseUri.host;
    final slugMatch = RegExp(r'/bpk-tv/([^/]+)/').firstMatch(targetUrl);
    final slug = slugMatch != null ? slugMatch.group(1)! : '';

    String dashBase = '';
    if (slug.isNotEmpty) {
      dashBase = 'https://$cdnHost/bpk-tv/$slug/WDVLive/dash/';
    } else {
      final lastSlash = targetUrl.lastIndexOf('/');
      dashBase = lastSlash != -1 ? '${targetUrl.substring(0, lastSlash + 1)}dash/' : '$targetUrl/';
    }

    _lastDashBase = dashBase;
    if (channelId != null) {
      _channelDashBase[channelId] = dashBase;
    }

    final effectiveCh = channelId ?? _lastChannelId ?? 0;
    final proxyDashBase = 'http://127.0.0.1:$_port/dash/$effectiveCh/';
    if (body.contains(RegExp(r'<BaseURL[^>]*>dash/<\/BaseURL>'))) {
      body = body.replaceAll(RegExp(r'<BaseURL[^>]*>dash/<\/BaseURL>'), '<BaseURL>$proxyDashBase</BaseURL>');
    } else if (body.contains('<BaseURL>')) {
      body = body.replaceAll(RegExp(r'<BaseURL[^>]*>[^<]*<\/BaseURL>'), '<BaseURL>$proxyDashBase</BaseURL>');
    } else if (body.contains('<Period')) {
      body = body.replaceFirst(RegExp(r'<Period[^>]*>'), '\$0\n    <BaseURL>$proxyDashBase</BaseURL>');
    }

    request.response.headers.contentType = ContentType('application', 'dash+xml');
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.headers.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    request.response.headers.set('Cache-Control', 'no-cache, no-store');
    request.response.write(body);
    await request.response.close();
  }

  static Future<void> _handleDrm(HttpRequest request, Map<String, String> query) async {
    final targetUrl = query['url'] ?? '';
    final chStr = query['ch'];
    final channelId = chStr != null ? int.tryParse(chStr) : null;

    if (targetUrl.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Missing url parameter');
      await request.response.close();
      return;
    }

    try {
      final session = HiveService.getSavedSession();
      if (session == null || !session.isValid) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.write('No active session');
        await request.response.close();
        return;
      }

      final activeToken = (channelId != null ? _channelDashHdnea[channelId] : null) ?? _lastDashHdnea;
      final bodyBytes = await request.fold<List<int>>([], (prev, element) => prev..addAll(element));

      final outgoingHeaders = <String, String>{
        'Content-Type': 'application/octet-stream',
        'User-Agent': 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7',
        'Connection': 'keep-alive',
        'os': 'android',
        'appName': 'RJIL_JioTV',
        'subscriberId': session.crmid,
        'ssotoken': session.ssoToken,
        'x-platform': 'android',
        'srno': _generateDateTime(),
        'crmid': session.crmid,
        'channelid': channelId != null ? channelId.toString() : '',
        'uniqueId': session.uniqueId,
        'versionCode': '422',
        'usergroup': 'tvYR7NSNn7rymo3F',
        'devicetype': 'phone',
        'osVersion': '13',
        'deviceId': '689f928e469502ab',
        'accesstoken': session.accessToken,
      };

      if (activeToken.isNotEmpty) {
        outgoingHeaders['Cookie'] = '__hdnea__=$activeToken';
      }

      debugPrint('[LOCAL_STREAM_PROXY] Forwarding ${bodyBytes.length} byte Widevine challenge for ch=$channelId to Jio license server');

      var licenseRes = await http.post(
        Uri.parse(targetUrl),
        headers: outgoingHeaders,
        body: bodyBytes,
      );

      // Reactive retry on 403 Forbidden with refreshed token
      if (licenseRes.statusCode == HttpStatus.forbidden && channelId != null) {
        debugPrint('[LOCAL_STREAM_PROXY] License server returned 403. Refreshing DASH token...');
        final freshToken = await refreshHdnea(channelId, isDash: true);
        if (freshToken != null) {
          outgoingHeaders['Cookie'] = '__hdnea__=$freshToken';
          var retryUrl = targetUrl;
          if (retryUrl.contains('__hdnea__=')) {
            retryUrl = retryUrl.replaceAll(RegExp(r'__hdnea__=[^&]+'), '__hdnea__=$freshToken');
          }
          licenseRes = await http.post(
            Uri.parse(retryUrl),
            headers: outgoingHeaders,
            body: bodyBytes,
          );
        }
      }

      debugPrint('[LOCAL_STREAM_PROXY] License server response: ${licenseRes.statusCode} (${licenseRes.bodyBytes.length} bytes)');

      request.response.statusCode = licenseRes.statusCode;
      request.response.headers.contentType = ContentType('application', 'octet-stream');
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.add(licenseRes.bodyBytes);
      await request.response.close();
    } catch (e) {
      debugPrint('[LOCAL_STREAM_PROXY_DRM_ERR] $e');
      request.response.statusCode = HttpStatus.badGateway;
      request.response.write('DRM error: $e');
      await request.response.close();
    }
  }

  static Future<void> _handleKey(HttpRequest request, Map<String, String> query) async {
    var keyUrl = query['url'] ?? '';
    final chStr = query['ch'];
    final channelId = chStr != null ? int.tryParse(chStr) : null;

    if (keyUrl.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Missing url parameter');
      await request.response.close();
      return;
    }

    if (_keyCache.containsKey(keyUrl)) {
      request.response.headers.contentType = ContentType('application', 'octet-stream');
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.headers.set('Cache-Control', 'max-age=3600');
      request.response.add(_keyCache[keyUrl]!);
      await request.response.close();
      return;
    }

    try {
      var keyRes = await http.get(Uri.parse(keyUrl), headers: {
        'User-Agent': 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7',
      });

      if (keyRes.statusCode == HttpStatus.forbidden && channelId != null) {
        final freshToken = await refreshHdnea(channelId);
        if (freshToken != null) {
          keyUrl = keyUrl.replaceAll(RegExp(r'__hdnea__=[^&]+'), '__hdnea__=$freshToken');
          keyRes = await http.get(Uri.parse(keyUrl), headers: {
            'User-Agent': 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7',
          });
        }
      }

      if (keyRes.statusCode == HttpStatus.ok && keyRes.bodyBytes.length == 16) {
        _keyCache[keyUrl] = keyRes.bodyBytes;
        request.response.headers.contentType = ContentType('application', 'octet-stream');
        request.response.headers.set('Access-Control-Allow-Origin', '*');
        request.response.headers.set('Cache-Control', 'max-age=3600');
        request.response.add(keyRes.bodyBytes);
      } else {
        debugPrint('[LOCAL_STREAM_PROXY_KEY_ERR] Status: ${keyRes.statusCode}, Bytes: ${keyRes.bodyBytes.length} for $keyUrl');
        request.response.statusCode = keyRes.statusCode;
        request.response.write('Key fetch failed with status: ${keyRes.statusCode}');
      }
    } catch (e) {
      debugPrint('[LOCAL_STREAM_PROXY_KEY_EXCEPTION] $e');
      request.response.statusCode = HttpStatus.badGateway;
      request.response.write('Key request exception: $e');
    }

    await request.response.close();
  }
}
