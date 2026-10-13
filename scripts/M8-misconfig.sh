#!/usr/bin/env bash
#
# M8 — Security Misconfiguration
# Revisa el manifiesto (allowBackup/debuggable/exported) y explota el backup.
#
# Rama: vuln/M8
# Uso:  ./scripts/M8-misconfig.sh [ruta-al.apk]
#
set -euo pipefail
source "$(dirname "$0")/_common.sh"

APK="$(require_apk "${1:-$APK_DEBUG}")"

# Localiza aapt2 en el SDK de Android.
AAPT2="$(ls -1 "$HOME"/Library/Android/sdk/build-tools/*/aapt2 2>/dev/null | sort -V | tail -1 || true)"

bold "M8 · Security Misconfiguration"
info "APK: $APK"

bold "1) Manifiesto: flags inseguros"
if [ -n "${AAPT2:-}" ] && [ -x "$AAPT2" ]; then
  "$AAPT2" dump xmltree --file AndroidManifest.xml "$APK" 2>/dev/null \
    | grep -iE "allowBackup|debuggable|usesCleartextTraffic|exported" | sort -u || true
else
  info "aapt2 no encontrado; revisando el fuente:"
  grep -rn -iE "allowBackup|debuggable|usesCleartextTraffic|exported" \
    "$ROOT/vuln_bank/android/app/src/main/AndroidManifest.xml" || true
fi

bold "2) Estado en el dispositivo (flags efectivos)"
if adb get-state >/dev/null 2>&1; then
  adb shell dumpsys package "$PKG" 2>/dev/null | grep -iE "flags=|debuggable|ALLOW_BACKUP" | head || true
else
  info "Sin dispositivo conectado."
fi

bold "3) Exfiltración vía backup (android:allowBackup=true)"
info "Comando (en baseline fallará / en vuln/M8 extraerá datos):"
echo "     adb backup -f /tmp/vulnbank.ab -apk $PKG"
if adb get-state >/dev/null 2>&1; then
  adb backup -f /tmp/vulnbank.ab -apk "$PKG" 2>/dev/null || true
  [ -s /tmp/vulnbank.ab ] && ok "Backup generado: /tmp/vulnbank.ab" || bad "Sin backup (allowBackup=false o sin confirmación)."
fi

echo
bold "Impacto: backup de datos, componentes expuestos y builds debug en producción."
bold "Fix (fix/M8): allowBackup=false, componentes no exportados, builds release."
