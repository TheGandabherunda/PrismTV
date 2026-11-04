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

const server = http.createServer((req, res) => {
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

  // 2. Stream Proxy (Rewrites HLS Playlists and Proxies Video Chunks)
  if (req.url.startsWith('/api/stream-proxy')) {
    const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
    const targetUrl = parsedUrl.searchParams.get('url');

    if (!targetUrl) {
      res.writeHead(400, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
      res.end('Missing url parameter');
      return;
    }

    try {
      const u = new URL(targetUrl);
      const isHttps = u.protocol === 'https:';
      const client = isHttps ? https : http;

      // Extract hdnea if present in query
      const hdneaToken = u.searchParams.get('hdnea') || u.searchParams.get('__hdnea__') || '';

      const outgoingHeaders = {
        'User-Agent': 'plaYtv/7.1.8 (Linux;Android 8.1.0) ExoPlayerLib/2.11.7',
        'Accept': '*/*',
        'Connection': 'keep-alive',
      };

      if (hdneaToken) {
        outgoingHeaders['Cookie'] = `__hdnea__=${hdneaToken}`;
      }

      const proxyReq = client.request(targetUrl, {
        method: req.method,
        headers: outgoingHeaders,
      }, (proxyRes) => {
        // Check for redirect (302/301)
        if (proxyRes.statusCode >= 300 && proxyRes.statusCode < 400 && proxyRes.headers.location) {
          const redirectUrl = new URL(proxyRes.headers.location, targetUrl).toString();
          res.writeHead(302, {
            'Location': `/api/stream-proxy?url=${encodeURIComponent(redirectUrl)}`,
            'Access-Control-Allow-Origin': '*',
          });
          res.end();
          return;
        }

        const contentType = proxyRes.headers['content-type'] || '';
        const isM3u8 = targetUrl.includes('.m3u8') || contentType.includes('mpegurl') || contentType.includes('application/x-mpegurl');

        if (isM3u8) {
          let body = '';
          proxyRes.setEncoding('utf8');
          proxyRes.on('data', chunk => body += chunk);
          proxyRes.on('end', () => {
            const baseUrl = targetUrl.substring(0, targetUrl.lastIndexOf('/') + 1);
            const parentSearch = u.search; // Contains ?hdnea=...

            const lines = body.split('\n');
            const rewritten = lines.map(line => {
              const trimmed = line.trim();
              if (!trimmed || trimmed.startsWith('#')) {
                // If the line contains URI="...", rewrite that URI as well (e.g. audio/subtitle tracks, keys)
                if (trimmed.includes('URI="')) {
                  return trimmed.replace(/URI="([^"]+)"/, (match, uri) => {
                    let fullUri = uri.startsWith('http') ? uri : new URL(uri, baseUrl).toString();
                    if (!fullUri.includes('?') && parentSearch) {
                      fullUri += parentSearch;
                    }
                    return `URI="/api/stream-proxy?url=${encodeURIComponent(fullUri)}"`;
                  });
                }
                return line;
              }

              let fullSegmentUrl = trimmed;
              if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
                fullSegmentUrl = new URL(trimmed, baseUrl).toString();
              }
              // If segment URL has no query params, attach the parent playlist's query (hdnea token)
              if (!fullSegmentUrl.includes('?') && parentSearch) {
                fullSegmentUrl += parentSearch;
              }

              return `/api/stream-proxy?url=${encodeURIComponent(fullSegmentUrl)}`;
            }).join('\n');

            res.writeHead(proxyRes.statusCode, {
              'Content-Type': 'application/vnd.apple.mpegurl',
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, OPTIONS',
              'Cache-Control': 'no-cache',
            });
            res.end(rewritten);
          });
        } else {
          // Binary video segments (.ts, .m4s)
          res.writeHead(proxyRes.statusCode, {
            ...proxyRes.headers,
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, OPTIONS',
          });
          proxyRes.pipe(res);
        }
      });

      proxyReq.on('error', (err) => {
        console.error('[STREAM PROXY ERROR]', err.message);
        res.writeHead(502, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
        res.end('Proxy Error: ' + err.message);
      });

      proxyReq.end();
      return;
    } catch (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
      res.end('Invalid URL');
      return;
    }
  }

  // 3. API Proxy for Jio Authentication & Playback APIs
  if (req.url.startsWith('/api/proxy/')) {
    const targetPath = req.url.replace('/api/proxy', '');
    console.log(`[API PROXY] ${req.method} -> https://jiotvapi.media.jio.com${targetPath}`);

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

      // Always enforce Jio expected headers
      proxyHeaders['host'] = 'jiotvapi.media.jio.com';
      proxyHeaders['user-agent'] = 'okhttp/4.12.0';

      // If accesstoken or accessToken header is present, ensure both casings exist
      const token = proxyHeaders['accesstoken'] || proxyHeaders['accesstoken'];
      if (token) {
        proxyHeaders['accesstoken'] = token;
        proxyHeaders['accessToken'] = token;
      }

      // If ssotoken or ssoToken header is present, ensure both casings exist
      const sso = proxyHeaders['ssotoken'] || proxyHeaders['ssotoken'];
      if (sso) {
        proxyHeaders['ssotoken'] = sso;
        proxyHeaders['ssoToken'] = sso;
      }

      if (bodyBuffer.length > 0) {
        proxyHeaders['content-length'] = bodyBuffer.length;
      }

      const proxyReq = https.request({
        hostname: 'jiotvapi.media.jio.com',
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
      'Cache-Control': 'no-cache',
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
