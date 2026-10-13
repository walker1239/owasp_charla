#!/usr/bin/env bash
#
# M6 — Inadequate Privacy Controls
# Demuestra fuga de PII en logs y permisos excesivos.
#
# Rama: vuln/M6
# Uso:  ./scripts/M6-privacy-leak.sh [segundos]
#
set -euo pipefail
source "$(dirname "$0")/_common.sh"

WAIT="${1:-20}"
bold "M6 · Inadequate Privacy Controls"

if ! adb get-state >/dev/null 2>&1; then
  bad "No hay dispositivo/emulador conectado (adb devices)."
  exit 1
fi

bold "1) Permisos declarados por la app"
adb shell dumpsys package "$PKG" 2>/dev/null | grep -E "granted=true|requested permissions" | head -20 || \
  info "Instala la app y repite."

bold "2) Fuga de PII en logcat (inicia sesión en la app ahora)"
adb logcat -c
info "Esperando $WAIT s ... usa la app (login) para generar logs."
sleep "$WAIT"
echo "  --- coincidencias sensibles ---"
adb logcat -d 2>/dev/null | grep -iE "VulnBank|password|@vulnbank\.com|token|card|saldo" | tail -40 || true

bold "3) Volcado de actividad reciente (posible PII en pantalla)"
adb shell dumpsys activity top 2>/dev/null | grep -iE "VulnBank|email|account" | head -10 || true

echo
bold "Impacto: PII y secretos quedan en logs accesibles a otras apps/MDM."
bold "Fix (fix/M6): no loguear PII, permisos mínimos, FLAG_SECURE, sin clipboard sensible."
