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

      const proxyReq = client.request(targetUrl, {
        method: req.method,
        headers: {
          'User-Agent': 'plaYtv/7.0.8 (Linux;Android 13) ExoPlayerLib/2.11.7',
          'Accept': '*/*',
          'Connection': 'keep-alive',
        }
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
            const lines = body.split('\n');
            const rewritten = lines.map(line => {
              const trimmed = line.trim();
              if (!trimmed || trimmed.startsWith('#')) {
                // If the line contains URI="...", rewrite that URI as well (e.g. audio/subtitle tracks, keys)
                if (trimmed.includes('URI="')) {
                  return trimmed.replace(/URI="([^"]+)"/, (match, uri) => {
                    const fullUri = uri.startsWith('http') ? uri : new URL(uri, baseUrl).toString();
                    return `URI="/api/stream-proxy?url=${encodeURIComponent(fullUri)}"`;
                  });
                }
                return line;
              }

              let fullSegmentUrl = trimmed;
              if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
                fullSegmentUrl = new URL(trimmed, baseUrl).toString();
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

    const proxyHeaders = { ...req.headers };
    delete proxyHeaders['host'];
    delete proxyHeaders['origin'];
    delete proxyHeaders['referer'];

    const proxyReq = https.request({
      hostname: 'jiotvapi.media.jio.com',
      port: 443,
      path: targetPath,
      method: req.method,
      headers: {
        ...proxyHeaders,
        host: 'jiotvapi.media.jio.com',
      }
    }, (proxyRes) => {
      const responseHeaders = { ...proxyRes.headers };
      responseHeaders['Access-Control-Allow-Origin'] = '*';
      responseHeaders['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
      responseHeaders['Access-Control-Allow-Headers'] = '*';

      res.writeHead(proxyRes.statusCode, responseHeaders);
      proxyRes.pipe(res);
    });

    proxyReq.on('error', (err) => {
      console.error('[API PROXY ERROR]', err.message);
      res.writeHead(502, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
      res.end(JSON.stringify({ error: 'Proxy request failed', details: err.message }));
    });

    req.pipe(proxyReq);
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
