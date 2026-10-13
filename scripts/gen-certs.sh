#!/usr/bin/env bash
#
# Genera una CA de desarrollo y el certificado del servidor para VulnBank.
# - CA:      backend/certs/ca.crt        (la confía la app en el baseline)
# - Servidor backend/certs/server.{crt,key}
# - Copia la CA a la app: vuln_bank/assets/certs/ca.crt
#
# Uso: ./scripts/gen-certs.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CERTS="$ROOT/backend/certs"
APP_CERTS="$ROOT/vuln_bank/assets/certs"

mkdir -p "$CERTS" "$APP_CERTS"

echo "[*] Generando CA de desarrollo ..."
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$CERTS/ca.key" -out "$CERTS/ca.crt" -days 3650 \
  -subj "/CN=VulnBank Dev CA/O=VulnBank" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" 2>/dev/null

echo "[*] Generando certificado de servidor (SAN: localhost, 127.0.0.1, 10.0.2.2) ..."
openssl req -newkey rsa:2048 -nodes \
  -keyout "$CERTS/server.key" -out "$CERTS/server.csr" \
  -subj "/CN=localhost/O=VulnBank" 2>/dev/null

openssl x509 -req -in "$CERTS/server.csr" \
  -CA "$CERTS/ca.crt" -CAkey "$CERTS/ca.key" -CAcreateserial \
  -out "$CERTS/server.crt" -days 3650 \
  -extfile <(printf "subjectAltName=DNS:localhost,IP:127.0.0.1,IP:10.0.2.2\nbasicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth") 2>/dev/null

cp "$CERTS/ca.crt" "$APP_CERTS/ca.crt"
rm -f "$CERTS/server.csr"

echo "[✓] Certificados generados:"
echo "    $CERTS/ca.crt"
echo "    $CERTS/server.crt"
echo "    $CERTS/server.key"
echo "    $APP_CERTS/ca.crt  (asset de la app)"
