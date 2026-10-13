#!/usr/bin/env bash
#
# M1 — Improper Credential Usage
# Extrae credenciales/API keys hardcodeadas del APK.
#
# Rama: vuln/M1   (en main esto NO encuentra nada)
# Uso:  ./scripts/M1-extract-secrets.sh [ruta-al.apk]
#
set -euo pipefail
source "$(dirname "$0")/_common.sh"

APK="$(require_apk "${1:-$APK_DEBUG}")"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

bold "M1 · Improper Credential Usage"
info "APK: $APK"
info "Desempaquetando ..."
unzip -o -q "$APK" -d "$WORK"

bold "1) Búsqueda de patrones de secretos en el binario (strings/grep)"
PATTERNS='sk_live_[A-Za-z0-9_]+|S3rv1c10|service[_-]?password|api[_-]?key|VLNBANK'
FOUND=0
while IFS= read -r line; do
  ok "$line"
  FOUND=1
done < <(grep -a -o -E "$PATTERNS" -r "$WORK" 2>/dev/null | sort -u | head -20 || true)

if [ "$FOUND" -eq 0 ]; then
  bad "No se encontraron secretos hardcodeados (comportamiento del baseline)."
fi

bold "2) (Opcional) Decompilar con jadx para leerlo en código"
if command -v jadx >/dev/null 2>&1; then
  jadx -q --no-res -d "$WORK/jadx" "$APK" >/dev/null 2>&1 || true
  grep -r -n -E "$PATTERNS" "$WORK/jadx" 2>/dev/null | head -10 || \
    info "jadx no mostró coincidencias en código (puede estar en libapp.so)."
else
  info "jadx no instalado (./scripts/setup-tools.sh)."
fi

bold "3) Volcado del string sospechoso completo"
if command -v strings >/dev/null 2>&1; then
  strings -a "$WORK/lib/arm64-v8a/libapp.so" 2>/dev/null | grep -E "$PATTERNS" | sort -u | head || true
fi

echo
bold "Impacto: quien tenga el APK puede extraer la credencial y usarla contra la API."
bold "Fix (fix/M1): no embebas secretos; usa Keystore/Keychain y tokens efímeros."
