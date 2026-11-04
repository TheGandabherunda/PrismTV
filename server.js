const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const PORT = process.env.PORT || 3000;
const WEB_ROOT = path.join(__dirname, 'build', 'web');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

// ---------------------------------------------------------------------------
// In-Memory & Persistent Session Cache
// ---------------------------------------------------------------------------
const SESSION_CACHE_FILE = path.join(__dirname, '.session_cache.json');
let currentSession = {
  accessToken: '',
  ssoToken: '',
  crmid: '',
  uniqueId: '',
  deviceId: '689f928e469502ab',
};

function loadSession() {
  try {
    if (fs.existsSync(SESSION_CACHE_FILE)) {
      const data = JSON.parse(fs.readFileSync(SESSION_CACHE_FILE, 'utf8'));
      currentSession = { ...currentSession, ...data };
      console.log('[SESSION] Loaded saved session for subscriber:', currentSession.crmid || 'Known');
    }
  } catch (e) {
    console.error('[SESSION] Failed to load session cache:', e.message);
  }
}

function updateSession(updates) {
  let changed = false;
  for (const [k, v] of Object.entries(updates)) {
    if (v && typeof v === 'string' && v.trim().length > 0 && currentSession[k] !== v.trim()) {
      currentSession[k] = v.trim();
      changed = true;
    }
  }
  if (changed) {
    try {
      fs.writeFileSync(SESSION_CACHE_FILE, JSON.stringify(currentSession, null, 2), 'utf8');
      console.log('[SESSION] Cache updated. SSOToken present:', !!currentSession.ssoToken, 'CRM:', currentSession.crmid);
    } catch (_) {}
  }
}

loadSession();

// In-memory cache for __hdnea__ tokens per channel/host
const activeHdneaTokens = new Map();

// Map of Broadpeak stream slugs to channel IDs for universal token refresh across all channels
const channelSlugToIdMap = new Map([
  ['Colors_Kannada_HD_MOB', '757'],
  ['CNHDKannada_MOB', '757'],
  ['Star_Plus_HD_MOB', '1132'],
  ['Ten_HD_MOB', '162'],
  ['ColorsHD_MOB', '144'],
  ['Sony_SAB_MOB', '154'],
  ['Sony_HD_MOB', '156'],
  ['Sony_Max_HD_MOB', '476'],
  ['SonyTen4Kan_MOB', '3585'],
  ['SonyTen2HD_MOB', '288'],
  ['SonyTen3HD_MOB', '287'],
  ['Udaya_HD_MOB', '901'],
  ['Zee_Kannada_HD_MOB', '884'],
  ['Zee_Cinema_HD_MOB', '474'],
  ['Zee_TV_HD_MOB', '153'],
  ['Star_Gold_HD_MOB', '475'],
  ['Star_Bharat_HD_MOB', '1133'],
  ['Star_Sports_1_HD_MOB', '283'],
  ['Star_Sports_2_HD_MOB', '285'],
  ['DD9_chandana_kannada_MOB', '713'],
  ['Chintu_TV_MOB', '710'],
  ['ColorsSuper_MOB', '759'],
  ['Pogo_Kan_MOB', '712'],
]);

function findChannelIdFromUrl(targetUrl) {
  if (!targetUrl) return '';
  const match = targetUrl.match(/\/bpk-tv\/([^\/]+)\//);
  if (match && channelSlugToIdMap.has(match[1])) {
    return channelSlugToIdMap.get(match[1]);
  }
  return '';
}

function refreshChannelHdnea(channelId, callback) {
  if (!currentSession.ssoToken || !currentSession.accessToken) {
    return callback(new Error('No session credentials'));
  }
  const now = new Date();
  const pad = n => String(n).padStart(2, '0');
  const beginStr = '' + now.getUTCFullYear() + pad(now.getUTCMonth()+1) + pad(now.getUTCDate()) + 'T' + pad(now.getUTCHours()) + pad(now.getUTCMinutes()) + pad(now.getUTCSeconds());
  const srnoStr = '' + now.getUTCFullYear() + pad(now.getUTCMonth()+1) + pad(now.getUTCDate());

  const effectiveId = String(channelId);
  const formBody = `channel_id=${effectiveId}&stream_type=Seek&begin=${beginStr}&srno=${srnoStr}`;

  const req = https.request('https://jiotvapi.media.jio.com/playback/apis/v1.1/geturl?langId=6', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'appkey': 'NzNiMDhlYzQyNjJm',
      'channel_id': effectiveId,
      'crmid': currentSession.crmid,
      'userId': currentSession.crmid,
      'subscriberId': currentSession.crmid,
      'uniqueId': currentSession.uniqueId,
      'deviceId': currentSession.deviceId || '689f928e469502ab',
      'devicetype': 'phone',
      'isott': 'false',
      'languageId': '6',
      'lbcookie': '1',
      'os': 'android',
      'osVersion': '13',
      'usergroup': 'tvYR7NSNn7rymo3F',
      'User-Agent': 'okhttp/4.12.0',
      'versionCode': '422',
      'accessToken': currentSession.accessToken,
      'accesstoken': currentSession.accessToken,
      'ssoToken': currentSession.ssoToken,
      'ssotoken': currentSession.ssoToken,
      'Content-Length': Buffer.byteLength(formBody),
    }
  }, (res) => {
    let data = '';
    res.on('data', d => data += d);
    res.on('end', () => {
      try {
        const json = JSON.parse(data);
        const resultUrl = (json.mpd && (json.mpd.result || (json.mpd.bitrates && (json.mpd.bitrates.high || json.mpd.bitrates.auto)))) ||
                          json.result ||
                          (json.bitrates && (json.bitrates.high || json.bitrates.auto)) || '';
        const match = resultUrl.match(/__hdnea__=([^&]+)/) || resultUrl.match(/hdnea=([^&]+)/);
        if (match) {
          const freshHdnea = match[1];
          activeHdneaTokens.set(channelId, freshHdnea);
          activeHdneaTokens.set(effectiveId, freshHdnea);
          console.log(`[HDNEA REFRESH] Successfully acquired fresh token for channel ${channelId}`);
          return callback(null, freshHdnea);
        }
      } catch (e) {}
      callback(new Error('Failed to parse refresh response: ' + data));
    });
  });
  req.on('error', callback);
  req.write(formBody);
  req.end();
}

const server = http.createServer((req, res) => {
  // 0. Support both root deployment (/) and subpath deployment (/prismTV/)
  let rawUrl = req.url;
  let urlPrefix = '';
  if (rawUrl.toLowerCase().startsWith('/prismtv/')) {
    urlPrefix = rawUrl.substring(0, '/prismtv'.length);
    req.url = rawUrl.substring('/prismtv'.length);
    if (!req.url.startsWith('/')) req.url = '/' + req.url;
  } else if (rawUrl.toLowerCase() === '/prismtv') {
    urlPrefix = rawUrl;
    req.url = '/';
  }

  const streamProxyPath = urlPrefix ? `${urlPrefix}/api/stream-proxy` : '/api/stream-proxy';

  // 1. Handle CORS Preflight for all endpoints
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': '*',
    });
    res.end();
    return;
  }

function generateDateTime() {
  const d = new Date();
  const pad = (n, l=2) => String(n).padStart(l, '0');
  const yy = pad(d.getUTCFullYear() % 100);
  const mm = pad(d.getUTCMonth() + 1);
  const dd = pad(d.getUTCDate());
  const hh = pad(d.getUTCHours());
  const mi = pad(d.getUTCMinutes());
  const ms = pad(d.getUTCMilliseconds(), 3);
  return `${yy}${mm}${dd}${hh}${mi}${ms}`;
}

// 1.5 Widevine DRM License Proxy
  if (req.url.startsWith('/api/drm-proxy')) {
    const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
    const targetUrl = parsedUrl.searchParams.get('url');
    let channelId = parsedUrl.searchParams.get('channel_id') || findChannelIdFromUrl(targetUrl);
    if (!channelId && targetUrl) {
      const u = new URL(targetUrl);
      channelId = u.searchParams.get('channel_id') || u.searchParams.get('channelid') || '';
    }

    if (!targetUrl) {
      res.writeHead(400, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
      res.end('Missing url parameter');
      return;
    }

    const bodyChunks = [];
    req.on('data', chunk => bodyChunks.push(chunk));
    req.on('end', () => {
      const challengeBuf = Buffer.concat(bodyChunks);

      const u = new URL(targetUrl);
      const isHttps = u.protocol === 'https:';
      const client = isHttps ? https : http;

      const activeSso = currentSession.ssoToken;
      const activeAccess = currentSession.accessToken;
      const activeCrm = currentSession.crmid;
      const activeUnique = currentSession.uniqueId;
      const activeDeviceId = currentSession.deviceId || '689f928e469502ab';

      const outgoingHeaders = {
        'Content-Type': 'application/octet-stream',
        'User-Agent': 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7',
        'Connection': 'keep-alive',
        'os': 'android',
        'appName': 'RJIL_JioTV',
        'subscriberId': activeCrm,
        'ssotoken': activeSso,
        'x-platform': 'android',
        'srno': generateDateTime(),
        'crmid': activeCrm,
        'channelid': String(channelId),
        'uniqueId': activeUnique,
        'versionCode': '422',
        'usergroup': 'tvYR7NSNn7rymo3F',
        'devicetype': 'phone',
        'Accept-Encoding': 'gzip, deflate',
        'osVersion': '13',
        'deviceId': activeDeviceId,
        'accesstoken': activeAccess,
        'Content-Length': challengeBuf.length,
      };

      const hdneaToken = u.searchParams.get('hdnea') || u.searchParams.get('__hdnea__') || activeHdneaTokens.get(channelId) || activeHdneaTokens.get(u.hostname) || '';
      if (hdneaToken) {
        outgoingHeaders['Cookie'] = `__hdnea__=${hdneaToken}`;
      }

      console.log(`[DRM PROXY] Forwarding ${challengeBuf.length} byte Widevine challenge for ch=${channelId} to Jio License Server`);

      const proxyReq = client.request(targetUrl, {
        method: 'POST',
        headers: outgoingHeaders,
      }, (proxyRes) => {
        console.log(`[DRM PROXY] Jio License response status: ${proxyRes.statusCode} (${proxyRes.headers['content-length'] || 0} bytes)`);
        res.writeHead(proxyRes.statusCode, {
          'Content-Type': 'application/octet-stream',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': '*',
        });
        proxyRes.pipe(res);
      });

      proxyReq.on('error', err => {
        console.error('[DRM PROXY ERROR]', err.message);
        res.writeHead(502, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
        res.end('DRM Proxy Error: ' + err.message);
      });

      if (challengeBuf.length > 0) {
        proxyReq.write(challengeBuf);
      }
      proxyReq.end();
    });
    return;
  }

  // 1.6 DASH Clock Sync (UTCTiming)
  if (req.url === '/api/dashtime' || req.url === '/dashtime') {
    res.writeHead(200, {
      'Content-Type': 'text/plain',
      'Access-Control-Allow-Origin': '*',
      'Cache-Control': 'no-cache',
    });
    res.end(new Date().toISOString());
    return;
  }

  // 1.8 Stream Proxy (Raw Path-Based for DASH segments)
  if (req.url.startsWith('/api/stream-proxy/raw/')) {
    let rawPath = req.url.substring('/api/stream-proxy/raw/'.length);
    let embeddedHdnea = '';
    let embeddedChannelId = '';

    if (rawPath.startsWith('hdnea/')) {
      rawPath = rawPath.substring('hdnea/'.length);
      const nextSlash = rawPath.indexOf('/');
      if (nextSlash !== -1) {
        embeddedHdnea = decodeURIComponent(rawPath.substring(0, nextSlash));
        rawPath = rawPath.substring(nextSlash + 1);
      }
    }
    if (rawPath.startsWith('ch/')) {
      rawPath = rawPath.substring('ch/'.length);
      const nextSlash = rawPath.indexOf('/');
      if (nextSlash !== -1) {
        embeddedChannelId = rawPath.substring(0, nextSlash);
        rawPath = rawPath.substring(nextSlash + 1);
      }
    }

    const slashIdx = rawPath.indexOf('/');
    const proto = rawPath.substring(0, slashIdx);
    const rest = rawPath.substring(slashIdx + 1);
    const targetUrl = `${proto}://${rest}`;

    try {
      const u = new URL(targetUrl);
      const isHttps = u.protocol === 'https:';
      const client = isHttps ? https : http;

      const channelId = embeddedChannelId || findChannelIdFromUrl(targetUrl) || (u.searchParams.get('channel_id')) || '';
      const hdneaToken = embeddedHdnea || u.searchParams.get('hdnea') || u.searchParams.get('__hdnea__') || activeHdneaTokens.get(channelId) || activeHdneaTokens.get(u.hostname) || '';

      const outgoingHeaders = {
        'User-Agent': 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7',
        'Accept': '*/*',
        'Connection': 'keep-alive',
      };
      if (req.headers['range']) {
        outgoingHeaders['Range'] = req.headers['range'];
      }
      if (hdneaToken) {
        outgoingHeaders['Cookie'] = `__hdnea__=${hdneaToken}`;
      }

      const executeRawRequest = (tokenOverride) => {
        if (tokenOverride) {
          outgoingHeaders['Cookie'] = `__hdnea__=${tokenOverride}`;
        }

        const proxyReq = client.request(targetUrl, {
          method: req.method,
          headers: outgoingHeaders,
        }, (proxyRes) => {
          if (proxyRes.statusCode === 403 && !tokenOverride) {
            console.log(`[STREAM RAW] 403 for ${targetUrl.split('?')[0]}. Refreshing token for channel ${channelId}...`);
            refreshChannelHdnea(channelId, (err, freshToken) => {
              if (!err && freshToken) {
                executeRawRequest(freshToken);
                return;
              }
              res.writeHead(403, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
              res.end('Access Denied');
            });
            return;
          }

          console.log(`[STREAM RAW] ${proxyRes.statusCode} <- ${targetUrl.split('?')[0]} (Cookie: ${outgoingHeaders['Cookie'] ? 'YES' : 'NO'})`);
          const respHeaders = {
            ...proxyRes.headers,
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, OPTIONS',
            'Access-Control-Expose-Headers': '*',
          };
          res.writeHead(proxyRes.statusCode, respHeaders);
          proxyRes.pipe(res);
        });

        proxyReq.on('error', (err) => {
          console.error('[STREAM RAW ERROR]', err.message);
          res.writeHead(502, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
          res.end('Raw Stream Error: ' + err.message);
        });

        proxyReq.end();
      };

      executeRawRequest(null);
      return;
    } catch (err) {
      res.writeHead(400, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
      res.end('Invalid raw URL');
      return;
    }
  }

  // 2. Stream Proxy (Rewrites HLS Playlists and Proxies Video Chunks & Decryption Keys)
  if (req.url.startsWith('/api/stream-proxy')) {
    const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
    const targetUrl = parsedUrl.searchParams.get('url');

    if (!targetUrl) {
      res.writeHead(400, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
      res.end('Missing url parameter');
      return;
    }

    // Capture query tokens if passed
    const qSso = parsedUrl.searchParams.get('ssotoken') || '';
    const qAccess = parsedUrl.searchParams.get('accesstoken') || '';
    const qCrm = parsedUrl.searchParams.get('crmid') || '';
    const qUnique = parsedUrl.searchParams.get('uniqueid') || '';
    const qChannelId = parsedUrl.searchParams.get('channel_id') || '';

    updateSession({
      ssoToken: qSso,
      accessToken: qAccess,
      crmid: qCrm,
      uniqueId: qUnique,
    });

    try {
      const u = new URL(targetUrl);
      const isHttps = u.protocol === 'https:';
      const client = isHttps ? https : http;

      const activeSso = qSso || currentSession.ssoToken;
      const activeAccess = qAccess || currentSession.accessToken;
      const activeCrm = qCrm || currentSession.crmid;
      const activeUnique = qUnique || currentSession.uniqueId;
      const activeDeviceId = currentSession.deviceId || '689f928e469502ab';
      const activeChannelId = qChannelId || findChannelIdFromUrl(targetUrl) || (u.searchParams.get('channel_id')) || '';

      // Extract hdnea if present in query, enclosing URL, or channel/hostname cache
      const hdneaToken = u.searchParams.get('hdnea') ||
                         u.searchParams.get('__hdnea__') ||
                         parsedUrl.searchParams.get('hdnea') ||
                         parsedUrl.searchParams.get('__hdnea__') ||
                         (activeChannelId ? activeHdneaTokens.get(activeChannelId) : null) ||
                         activeHdneaTokens.get(u.hostname) || '';
      if (hdneaToken) {
        if (activeChannelId) activeHdneaTokens.set(activeChannelId, hdneaToken);
        activeHdneaTokens.set(u.hostname, hdneaToken);
      }

      const isKeyRequest = u.hostname === 'tv.media.jio.com' ||
                           targetUrl.includes('.key') ||
                           targetUrl.includes('.pkey') ||
                           targetUrl.includes('hls/aes128');

      const outgoingHeaders = {};

      if (isKeyRequest) {
        // Upstream Jio key endpoint requires strict Android app headers and rejects browser headers
        outgoingHeaders['User-Agent'] = 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7';
        outgoingHeaders['appkey'] = 'NzNiMDhlYzQyNjJm';
        if (activeSso) outgoingHeaders['ssotoken'] = activeSso;
        if (activeAccess) {
          outgoingHeaders['accesstoken'] = activeAccess;
          outgoingHeaders['accessToken'] = activeAccess;
        }
        if (activeChannelId) outgoingHeaders['channelId'] = activeChannelId;
        if (activeCrm) {
          outgoingHeaders['crmid'] = activeCrm;
          outgoingHeaders['userId'] = activeCrm;
          outgoingHeaders['subscriberId'] = activeCrm;
        }
        if (activeUnique) outgoingHeaders['uniqueId'] = activeUnique;
        outgoingHeaders['deviceId'] = activeDeviceId;
        outgoingHeaders['devicetype'] = 'phone';
        outgoingHeaders['isott'] = 'false';
        outgoingHeaders['languageId'] = '6';
        outgoingHeaders['lbcookie'] = '1';
        outgoingHeaders['os'] = 'android';
        outgoingHeaders['osVersion'] = '13';
        outgoingHeaders['srno'] = '230203144000';
        outgoingHeaders['usergroup'] = 'tvYR7NSNn7rymo3F';
        outgoingHeaders['versionCode'] = '422';

        const cookies = [];
        if (activeSso) cookies.push(`ssotoken=${activeSso}`);
        if (hdneaToken) cookies.push(`__hdnea__=${hdneaToken}`);
        for (const [k, v] of u.searchParams.entries()) {
          if (k !== 'ssotoken' && k !== '__hdnea__' && k !== 'hdnea') {
            cookies.push(`${k}=${v}`);
          }
        }
        if (cookies.length > 0) {
          outgoingHeaders['Cookie'] = cookies.join('; ');
        }
      } else {
        // Media playlists (.m3u8) and video segments (.ts/.m4s) from CDN
        outgoingHeaders['User-Agent'] = 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7';
        outgoingHeaders['Accept'] = '*/*';
        outgoingHeaders['Connection'] = 'keep-alive';

        if (req.headers['range']) {
          outgoingHeaders['Range'] = req.headers['range'];
        }

        // Broadpeak / Akamai CDN only validates __hdnea__
        if (hdneaToken) {
          outgoingHeaders['Cookie'] = `__hdnea__=${hdneaToken}`;
        } else if (req.headers['cookie']) {
          outgoingHeaders['Cookie'] = req.headers['cookie'];
        }
      }

      function processStreamResponse(proxyRes, effectiveHdnea) {
        // Check for redirect (302/301)
        if (proxyRes.statusCode >= 300 && proxyRes.statusCode < 400 && proxyRes.headers.location) {
          const redirectUrl = new URL(proxyRes.headers.location, targetUrl).toString();
          let proxyLocation = `${streamProxyPath}?url=${encodeURIComponent(redirectUrl)}`;
          if (activeSso) proxyLocation += `&ssotoken=${encodeURIComponent(activeSso)}`;
          if (activeAccess) proxyLocation += `&accesstoken=${encodeURIComponent(activeAccess)}`;
          if (activeCrm) proxyLocation += `&crmid=${encodeURIComponent(activeCrm)}`;
          if (activeChannelId) proxyLocation += `&channel_id=${encodeURIComponent(activeChannelId)}`;
          if (effectiveHdnea) proxyLocation += `&hdnea=${encodeURIComponent(effectiveHdnea)}`;

          res.writeHead(302, {
            'Location': proxyLocation,
            'Access-Control-Allow-Origin': '*',
          });
          res.end();
          return;
        }

        const contentType = proxyRes.headers['content-type'] || '';
        const isMpd = targetUrl.includes('.mpd') || contentType.includes('dash+xml');
        const isM3u8 = targetUrl.includes('.m3u8') || contentType.includes('mpegurl') || contentType.includes('application/x-mpegurl');

        if (isMpd) {
          let body = '';
          proxyRes.setEncoding('utf8');
          proxyRes.on('data', chunk => body += chunk);
          proxyRes.on('end', () => {
            const baseUrl = targetUrl.substring(0, targetUrl.lastIndexOf('/') + 1);
            const hdneaPart = effectiveHdnea ? `hdnea/${encodeURIComponent(effectiveHdnea)}/` : '';
            const chPart = activeChannelId ? `ch/${activeChannelId}/` : '';

            let rewritten = body;
            if (rewritten.includes('<BaseURL>')) {
              rewritten = rewritten.replace(/<BaseURL>([^<]+)<\/BaseURL>/g, (match, rel) => {
                const fullBase = new URL(rel, baseUrl).toString();
                const noProto = fullBase.replace(/^https?:\/\//, '');
                const proxyBase = `${streamProxyPath}/raw/${hdneaPart}${chPart}${fullBase.startsWith('https') ? 'https' : 'http'}/${noProto}`;
                return `<BaseURL>${proxyBase}</BaseURL>`;
              });
            } else {
              const noProto = baseUrl.replace(/^https?:\/\//, '');
              const proxyBase = `${streamProxyPath}/raw/${hdneaPart}${chPart}${baseUrl.startsWith('https') ? 'https' : 'http'}/${noProto}`;
              rewritten = rewritten.replace(/<Period([^>]*)>/, `<Period$1>\n<BaseURL>${proxyBase}</BaseURL>`);
            }

            if (!rewritten.includes('<UTCTiming')) {
              rewritten = rewritten.replace(/<MPD([^>]*)>/, `<MPD$1><UTCTiming schemeIdUri="urn:mpeg:dash:utc:http-xsdate:2014" value="/api/dashtime"/>`);
            }

            const respHeaders = {
              'Content-Type': 'application/dash+xml',
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, OPTIONS',
              'Access-Control-Expose-Headers': '*',
              'Cache-Control': 'no-cache',
            };
            res.writeHead(proxyRes.statusCode, respHeaders);
            res.end(rewritten);
          });
          return;
        }

        if (isM3u8) {
          let body = '';
          proxyRes.setEncoding('utf8');
          proxyRes.on('data', chunk => body += chunk);
          proxyRes.on('end', () => {
            const baseUrl = targetUrl.substring(0, targetUrl.lastIndexOf('/') + 1);
            const parentSearch = u.search;

            const lines = body.split('\n');
            const rewritten = lines.map(line => {
              const trimmed = line.trim();
              if (!trimmed || trimmed.startsWith('#')) {
                if (trimmed.includes('URI="')) {
                  return trimmed.replace(/URI="([^"]+)"/, (match, uri) => {
                    let fullUri = uri.startsWith('http') ? uri : new URL(uri, baseUrl).toString();
                    if (effectiveHdnea && !fullUri.includes('hdnea=')) {
                      const sep = fullUri.includes('?') ? '&' : '?';
                      fullUri += `${sep}__hdnea__=${effectiveHdnea}`;
                    } else if (!fullUri.includes('?') && parentSearch) {
                      fullUri += parentSearch;
                    }

                    let proxyUri = `${streamProxyPath}?url=${encodeURIComponent(fullUri)}`;
                    if (activeSso) proxyUri += `&ssotoken=${encodeURIComponent(activeSso)}`;
                    if (activeAccess) proxyUri += `&accesstoken=${encodeURIComponent(activeAccess)}`;
                    if (activeCrm) proxyUri += `&crmid=${encodeURIComponent(activeCrm)}`;
                    if (activeChannelId) proxyUri += `&channel_id=${encodeURIComponent(activeChannelId)}`;
                    if (effectiveHdnea) proxyUri += `&hdnea=${encodeURIComponent(effectiveHdnea)}`;

                    return `URI="${proxyUri}"`;
                  });
                }
                return line;
              }

              let fullSegmentUrl = trimmed;
              if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
                fullSegmentUrl = new URL(trimmed, baseUrl).toString();
              }
              if (effectiveHdnea && !fullSegmentUrl.includes('hdnea=')) {
                const sep = fullSegmentUrl.includes('?') ? '&' : '?';
                fullSegmentUrl += `${sep}__hdnea__=${effectiveHdnea}`;
              } else if (!fullSegmentUrl.includes('?') && parentSearch) {
                fullSegmentUrl += parentSearch;
              }

              let proxySegment = `${streamProxyPath}?url=${encodeURIComponent(fullSegmentUrl)}`;
              if (activeSso) proxySegment += `&ssotoken=${encodeURIComponent(activeSso)}`;
              if (activeChannelId) proxySegment += `&channel_id=${encodeURIComponent(activeChannelId)}`;
              if (effectiveHdnea) proxySegment += `&hdnea=${encodeURIComponent(effectiveHdnea)}`;

              return proxySegment;
            }).join('\n');

            const respHeaders = {
              'Content-Type': 'application/vnd.apple.mpegurl',
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, OPTIONS',
              'Access-Control-Expose-Headers': '*',
              'Cache-Control': 'no-cache',
            };
            if (proxyRes.headers['set-cookie']) {
              respHeaders['Set-Cookie'] = proxyRes.headers['set-cookie'];
            }

            res.writeHead(proxyRes.statusCode, respHeaders);
            res.end(rewritten);
          });
          return;
        }

        // Direct media streaming (.ts, .m4s, key bytes)
        const respHeaders = {
          ...proxyRes.headers,
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, OPTIONS',
          'Access-Control-Expose-Headers': '*',
        };
        delete respHeaders['content-security-policy'];
        res.writeHead(proxyRes.statusCode, respHeaders);
        proxyRes.pipe(res);
      }

      const proxyReq = client.request(targetUrl, {
        method: req.method,
        headers: outgoingHeaders,
      }, (proxyRes) => {
        console.log(`[STREAM PROXY] ${proxyRes.statusCode} <- ${targetUrl.split('?')[0]}`);

        // If 403 (token expired or missing), auto-refresh token and retry once for ANY channel
        const targetChannelId = activeChannelId || findChannelIdFromUrl(targetUrl);
        if (proxyRes.statusCode === 403 && !req._hasRetried403 && targetChannelId) {
          req._hasRetried403 = true;
          console.warn(`[STREAM PROXY] 403 encountered for ${targetUrl.split('?')[0]}. Auto-refreshing token for channel ${targetChannelId}...`);
          return refreshChannelHdnea(targetChannelId, (refreshErr, freshHdnea) => {
            if (refreshErr || !freshHdnea) {
              return processStreamResponse(proxyRes, hdneaToken);
            }
            outgoingHeaders['Cookie'] = `__hdnea__=${freshHdnea}`;
            const retryReq = client.request(targetUrl, {
              method: req.method,
              headers: outgoingHeaders,
            }, (retryRes) => {
              console.log(`[STREAM PROXY RETRY] ${retryRes.statusCode} <- ${targetUrl.split('?')[0]}`);
              processStreamResponse(retryRes, freshHdnea);
            });
            retryReq.on('error', (err) => {
              res.writeHead(502, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
              res.end('Stream Error on Retry: ' + err.message);
            });
            retryReq.end();
          });
        }

        processStreamResponse(proxyRes, hdneaToken);
      });

      proxyReq.on('error', (err) => {
        console.error('[STREAM PROXY ERROR]', err.message);
        res.writeHead(502, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
        res.end('Proxy Error: ' + err.message);
      });

      proxyReq.end();
      return;
    } catch (err) {
      console.error('[STREAM PROXY EXCEPTION]', err.message, err.stack);
      res.writeHead(500, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
      res.end('Invalid URL: ' + err.message);
      return;
    }
  }

  // 3. API Proxy for Authentication & Playback APIs
  if (req.url.startsWith('/api/proxy/')) {
    const targetPath = req.url.replace('/api/proxy', '');

    // Select domain based on upstream service architecture
    let upstreamHost = 'jiotvapi.media.jio.com';
    if (targetPath.startsWith('/apis/v2.0/')) {
      upstreamHost = 'tv.media.jio.com';
    } else if (targetPath.startsWith('/tokenservice/')) {
      upstreamHost = 'auth.media.jio.com';
    }

    console.log(`[API PROXY] ${req.method} -> https://${upstreamHost}${targetPath}`);

    const chunks = [];
    req.on('data', chunk => chunks.push(chunk));
    req.on('end', () => {
      const bodyBuffer = Buffer.concat(chunks);

      const proxyHeaders = { ...req.headers };
      delete proxyHeaders['host'];
      delete proxyHeaders['origin'];
      delete proxyHeaders['referer'];
      delete proxyHeaders['connection'];
      delete proxyHeaders['content-length'];

      proxyHeaders['host'] = upstreamHost;
      proxyHeaders['user-agent'] = 'okhttp/4.12.0';

      // Capture and ensure both casings for tokens
      const token = proxyHeaders['accesstoken'] || proxyHeaders['accesstoken'];
      if (token) {
        proxyHeaders['accesstoken'] = token;
        proxyHeaders['accessToken'] = token;
      }

      const sso = proxyHeaders['ssotoken'] || proxyHeaders['ssotoken'];
      if (sso) {
        proxyHeaders['ssotoken'] = sso;
        proxyHeaders['ssoToken'] = sso;
      }

      // Update in-memory session cache from request headers
      updateSession({
        accessToken: token,
        ssoToken: sso,
        crmid: proxyHeaders['crmid'] || proxyHeaders['subscriberid'] || proxyHeaders['userid'],
        uniqueId: proxyHeaders['uniqueid'],
        deviceId: proxyHeaders['deviceid'],
      });

      if (bodyBuffer.length > 0) {
        proxyHeaders['content-length'] = bodyBuffer.length;
      }

      const proxyReq = https.request({
        hostname: upstreamHost,
        port: 443,
        path: targetPath,
        method: req.method,
        headers: proxyHeaders,
      }, (proxyRes) => {
        const resChunks = [];
        proxyRes.on('data', c => resChunks.push(c));
        proxyRes.on('end', () => {
          const resBuffer = Buffer.concat(resChunks);
          console.log(`[API PROXY RESP] ${proxyRes.statusCode} for ${targetPath} (Length: ${resBuffer.length})`);
          if (proxyRes.statusCode !== 200 && proxyRes.statusCode !== 204) {
            console.log(`[API PROXY ERR BODY]`, resBuffer.toString('utf8'));
          }

          // Try to capture session attributes from successful responses (e.g. login/verify, token refresh)
          if (proxyRes.statusCode === 200) {
            try {
              const json = JSON.parse(resBuffer.toString('utf8'));
              const authToken = json.authToken || json.accessToken;
              const ssoToken = json.ssoToken;
              const sessionAttrs = json.sessionAttributes || {};
              const user = sessionAttrs.user || {};
              const crm = user.subscriberId || user.crmid;
              const unique = user.unique || user.uniqueId;
              updateSession({
                accessToken: authToken,
                ssoToken: ssoToken,
                crmid: crm,
                uniqueId: unique,
              });

              if (targetPath.includes('/playback/')) {
                const requestedChId = proxyHeaders['channel_id'] || (bodyBuffer.toString('utf8').match(/channel_id=(\d+)/) || [])[1];
                const resultUrl = (json.mpd && (json.mpd.result || (json.mpd.bitrates && (json.mpd.bitrates.high || json.mpd.bitrates.auto)))) || json.result || '';
                const slugMatch = resultUrl.match(/\/bpk-tv\/([^\/]+)\//);
                if (slugMatch && requestedChId) {
                  channelSlugToIdMap.set(slugMatch[1], String(requestedChId));
                  console.log(`[CHANNEL MAP] Associated slug ${slugMatch[1]} with channelId ${requestedChId}`);
                }
              }
            } catch (_) {}
          }

          const responseHeaders = { ...proxyRes.headers };
          responseHeaders['Access-Control-Allow-Origin'] = '*';
          responseHeaders['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
          responseHeaders['Access-Control-Allow-Headers'] = '*';
          delete responseHeaders['content-length'];

          res.writeHead(proxyRes.statusCode, responseHeaders);
          res.end(resBuffer);
        });
      });

      proxyReq.on('error', (err) => {
        console.error('[API PROXY ERROR]', err.message);
        res.writeHead(502, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
        res.end(JSON.stringify({ error: 'Proxy request failed', details: err.message }));
      });

      if (bodyBuffer.length > 0) {
        proxyReq.write(bodyBuffer);
      }
      proxyReq.end();
    });
    return;
  }

  // 4. Serve Static Web Files
  let reqPath = decodeURI(req.url.split('?')[0]);
  if (reqPath === '/' || reqPath === '') {
    reqPath = '/index.html';
  }

  const safePath = path.normalize(reqPath).replace(/^(\.\.[\/\\])+/, '');
  let filePath = path.join(WEB_ROOT, safePath);

  if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
    filePath = path.join(filePath, 'index.html');
  }

  if (!fs.existsSync(filePath)) {
    filePath = path.join(WEB_ROOT, 'index.html');
  }

  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, content) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Server Error');
      return;
    }

    res.writeHead(200, {
      'Content-Type': contentType,
      'Access-Control-Allow-Origin': '*',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    });
    res.end(content);
  });
});

server.listen(PORT, () => {
  console.log(`\n==================================================`);
  console.log(`  PRISM TV (TheGandabherunda) Live Local Preview`);
  console.log(`==================================================`);
  console.log(`  Local URL:    http://localhost:${PORT}`);
  console.log(`  API Proxy:    http://localhost:${PORT}/api/proxy/`);
  console.log(`  Stream Proxy: http://localhost:${PORT}/api/stream-proxy?url=`);
  console.log(`==================================================\n`);
});
