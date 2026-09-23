#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
umask 077
lan_ip="${DEV_LAN_IP:-$(ipconfig getifaddr en0 2>/dev/null || true)}"
if [[ -n "$lan_ip" ]] && ! node -e 'process.exit(require("node:net").isIP(process.argv[1]) === 4 ? 0 : 1)' "$lan_ip"; then
  echo "DEV_LAN_IP must be an IPv4 address" >&2; exit 1
fi
cert_dir=.local/dev-https
mkdir -p "$cert_dir"
if [[ ! -f "$cert_dir/ca.pem" ]]; then
  openssl req -x509 -newkey rsa:2048 -nodes -days 365 -sha256 \
    -keyout "$cert_dir/ca-key.pem" -out "$cert_dir/ca.pem" \
    -subj '/CN=Freeva Local Development CA' \
    -addext 'basicConstraints=critical,CA:TRUE' \
    -addext 'keyUsage=critical,keyCertSign,cRLSign'
fi
if [[ ! -f "$cert_dir/server.pem" ]] || [[ "$(cat "$cert_dir/lan-ip" 2>/dev/null || true)" != "$lan_ip" ]] || ! openssl x509 -checkend 86400 -noout -in "$cert_dir/server.pem"; then
  openssl req -newkey rsa:2048 -nodes \
    -keyout "$cert_dir/server-key.pem" -out "$cert_dir/server.csr" \
    -subj '/CN=localhost'
  cat > "$cert_dir/server.ext" <<EXT
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:localhost,IP:127.0.0.1,IP:10.0.2.2${lan_ip:+,IP:$lan_ip}
EXT
  openssl x509 -req -in "$cert_dir/server.csr" \
    -CA "$cert_dir/ca.pem" -CAkey "$cert_dir/ca-key.pem" -CAcreateserial \
    -out "$cert_dir/server.pem" -days 90 -sha256 -extfile "$cert_dir/server.ext"
  printf '%s' "$lan_ip" > "$cert_dir/lan-ip"
fi
openssl verify -CAfile "$cert_dir/ca.pem" "$cert_dir/server.pem"
node infra/dev/write-mobile-config.cjs "$lan_ip"
