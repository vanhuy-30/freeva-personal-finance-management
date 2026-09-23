// MOB-P1-001: HTTPS for mobile development, no request/PII logs.
const https = require('node:https');
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const directory = path.resolve(__dirname, '../../.local/dev-https');
const server = https.createServer({
  key: fs.readFileSync(path.join(directory, 'server-key.pem')),
  cert: fs.readFileSync(path.join(directory, 'server.pem')),
  minVersion: 'TLSv1.2',
}, (request, response) => {
  const upstream = http.request({
    hostname: '127.0.0.1', port: 4000,
    path: request.url, method: request.method,
    headers: { ...request.headers, host: 'localhost:4000' },
    timeout: 20_000,
  }, (incoming) => {
    response.writeHead(incoming.statusCode, incoming.headers);
    incoming.on('error', () => response.destroy());
    incoming.pipe(response);
  });
  upstream.on('timeout', () => upstream.destroy());
  upstream.on('error', () => {
    if (!response.headersSent) response.writeHead(502);
    response.end();
  });
  request.on('aborted', () => upstream.destroy());
  response.on('close', () => upstream.destroy());
  request.pipe(upstream);
});
server.listen(8443, process.env.DEV_HTTPS_BIND ?? '127.0.0.1', () => {
  console.log('Dev HTTPS proxy: https://localhost:8443 -> local API port 4000');
});
