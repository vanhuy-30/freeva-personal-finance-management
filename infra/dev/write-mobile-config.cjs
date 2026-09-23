// Public CA only; private keys remain in the ignored .local directory.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const ca = fs.readFileSync(path.join(root, '.local/dev-https/ca.pem')).toString('base64');
const hosts = { dev: 'localhost', 'dev-android': '10.0.2.2' };
if (process.argv[2]) hosts['dev-device'] = process.argv[2];
for (const [name, host] of Object.entries(hosts)) {
  fs.writeFileSync(path.join(root, `apps/mobile/config/${name}.json`), JSON.stringify({
    APP_ENV: 'dev', API_BASE_URL: `https://${host}:8443`, DEV_CA_CERT_BASE64: ca,
  }, null, 2) + '\n', { mode: 0o600 });
}
if (!process.argv[2]) {
  fs.rmSync(path.join(root, 'apps/mobile/config/dev-device.json'), { force: true });
  console.log('No LAN IPv4 found; set DEV_LAN_IP to generate physical-device config.');
}
console.log('Mobile dev configs generated. Development CA is trusted only by debug dev builds.');
