#!/usr/bin/env bash
#
# M5 — Insecure Communication
# Intercepta el tráfico con mitmproxy para robar credenciales.
#
# Rama: vuln/M5   (en main el pinning impide la intercepción)
# Uso:  ./scripts/M5-mitm-setup.sh [--run]   # --run arranca mitmproxy
#
set -euo pipefail
source "$(dirname "$0")/_common.sh"

PORT="${MITM_PORT:-8081}"
bold "M5 · Insecure Communication (MITM)"

bold "1) Comprobación del pinning de la app (Dart)"
grep -n "withTrustedRoots\|badCertificateCallback\|setTrustedCertificatesBytes" \
  "$ROOT/vuln_bank/lib/core/api_client.dart" || true
info "withTrustedRoots:false + CA fijada  => pinning ACTIVO (baseline)."
info "badCertificateCallback => true      => pinning DESACTIVADO (vuln/M5)."

bold "2) Herramienta de interceptación"
command -v mitmproxy >/dev/null 2>&1 && ok "mitmproxy instalado" || {
  bad "mitmproxy no instalado: ./scripts/setup-tools.sh"; }

bold "3) Pasos"
cat <<EOF
  a) Arranca el proxy:
       mitmproxy -p $PORT
  b) Emulador Android con proxy hacia el host del Mac:
       emulator -avd Pixel_6 -http-proxy http://10.0.2.2:$PORT
  c) Instala la CA de mitmproxy como CA de USUARIO en el dispositivo:
       adb push ~/.mitmproxy/mitmproxy-ca-cert.cer /sdcard/Download/
       # Ajustes → Seguridad → Cifrado y credenciales → Instalar certificado → CA
  d) Usa la app (login). Observa en mitmproxy la petición POST /login
     con usuario y contraseña en claro.
  e) iOS simulador: Ajustes → Wi-Fi → (i) → Proxy → Manual → 127.0.0.1:$PORT
EOF

if [ "${1:-}" = "--run" ]; then
  bold "Arrancando mitmproxy en :$PORT (Ctrl-C para salir) ..."
  mitmproxy -p "$PORT"
fi

echo
bold "Impacto: robo de credenciales y manipulación de operaciones bancarias."
bold "Fix (fix/M5): TLS obligatorio, certificate pinning, ATS/networkSecurityConfig estrictos."
