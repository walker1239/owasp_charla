#!/usr/bin/env bash
#
# M7 — Insufficient Binary Protections
# Demuestra ingeniería inversa y reempaquetado (repackaging) del APK.
#
# Rama: vuln/M7   (baseline sin ofuscación ni anti-tamper)
# Uso:  ./scripts/M7-binary-repack.sh [ruta-al.apk]
#
set -euo pipefail
source "$(dirname "$0")/_common.sh"

APK="$(require_apk "${1:-$APK_RELEASE}")"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

bold "M7 · Insufficient Binary Protections"
info "APK: $APK"

bold "1) Ingeniería inversa con jadx (código legible)"
if command -v jadx >/dev/null 2>&1; then
  jadx -q --no-res -d "$WORK/jadx" "$APK" >/dev/null 2>&1 || true
  ok "Fuentes descompiladas en $WORK/jadx"
  grep -rn -E "class .*ApiClient|sk_live_|password" "$WORK/jadx" 2>/dev/null | head -8 || true
else
  bad "jadx no instalado (./scripts/setup-tools.sh)."
fi

bold "2) Reempaquetado con apktool (sin anti-tamper, se puede modificar y re-firmar)"
if command -v apktool >/dev/null 2>&1; then
  apktool d -f -o "$WORK/decoded" "$APK" >/dev/null 2>&1 && ok "Decodificado en $WORK/decoded"
  info "Aquí modificarías smali/recursos (p. ej. saltarte la validación)."
  apktool b "$WORK/decoded" -o "$WORK/repacked.apk" >/dev/null 2>&1 && ok "Reconstruido: $WORK/repacked.apk"
  info "Re-firma con tu propio keystore y instálalo como actualización."
else
  bad "apktool no instalado (./scripts/setup-tools.sh)."
fi

bold "3) ¿Hay protección anti-root / anti-tamper?"
if grep -rq -E "isRooted|jailbreak|frida|SafetyNet|PlayIntegrity" "$ROOT/vuln_bank/lib" 2>/dev/null; then
  ok "Se detectan comprobaciones (fix aplicado)."
else
  bad "No hay detección de root/tampering ni verificación de integridad."
fi

bold "4) Build sin ofuscación"
grep -n "obfuscate\|split-debug-info" "$ROOT/vuln_bank"/*.sh 2>/dev/null || \
  info "El build de release no usa --obfuscate --split-debug-info."

echo
bold "Impacto: el binario se lee, modifica y redistribuye libremente."
bold "Fix (fix/M7): ofuscación, R8, anti-root/tamper, verificación de firma."
