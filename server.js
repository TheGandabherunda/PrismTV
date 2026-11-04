const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

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
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, appname, os, devicetype, ssotoken, uniqueId, crmid, accesstoken, appkey',
    });
    res.end();
    return;
  }

  // 2. Built-in CORS Proxy for Web Preview
  if (req.url.startsWith('/api/proxy/')) {
    const targetPath = req.url.replace('/api/proxy', '');
    console.log(`[PROXY] ${req.method} -> https://jiotvapi.media.jio.com${targetPath}`);

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
      console.error('[PROXY ERROR]', err.message);
      res.writeHead(502, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
      res.end(JSON.stringify({ error: 'Proxy request failed', details: err.message }));
    });

    req.pipe(proxyReq);
    return;
  }

  // 3. Serve Static Web Files
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
  console.log(`  Local URL:   http://localhost:${PORT}`);
  console.log(`  CORS Proxy:  http://localhost:${PORT}/api/proxy/`);
  console.log(`==================================================\n`);
});
