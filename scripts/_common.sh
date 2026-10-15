#!/usr/bin/env bash
# Variables y helpers compartidos por los scripts de explotación de VulnBank.
# Uso: source "$(dirname "$0")/_common.sh"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PKG="com.pragma.vulnbank.vuln_bank"
APK_DEBUG="$ROOT/vuln_bank/build/app/outputs/flutter-apk/app-debug.apk"
APK_RELEASE="$ROOT/vuln_bank/build/app/outputs/flutter-apk/app-release.apk"
CA="$ROOT/backend/certs/ca.crt"
API_BASE="${API_BASE:-https://localhost:8443}"

bold() { printf "\033[1m%s\033[0m\n" "$*"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$*"; }
bad()  { printf "  \033[31m✗\033[0m %s\n" "$*"; }
info() { printf "  · %s\n" "$*"; }

# Crea un token JWT de sesión para ataques (usa jq si está; si no, python3).
login_token() {
  local email="${1:-ana@vulnbank.com}" password="${2:-password123}"
  curl -s --cacert "$CA" -X POST "$API_BASE/login" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$email\",\"password\":\"$password\"}" \
    | python3 -c 'import sys,json; print(json.load(sys.stdin).get("token",""))'
}

require_apk() {
  local apk="${1:-$APK_DEBUG}"
  if [ ! -f "$apk" ]; then
    bold "APK no encontrado: $apk"
    info "Compílalo con: (cd \"$ROOT/vuln_bank\" && flutter build apk --debug)"
    exit 1
  fi
  echo "$apk"
}

# Resuelve el APK a analizar.
#   resolve_apk            -> release si existe, si no debug
#   resolve_apk release    -> app-release.apk
#   resolve_apk debug      -> app-debug.apk
#   resolve_apk /ruta.apk  -> esa ruta
resolve_apk() {
  local sel="${1:-auto}"
  case "$sel" in
    ""|auto)
      if [ -f "$APK_RELEASE" ]; then echo "$APK_RELEASE"
      elif [ -f "$APK_DEBUG" ]; then echo "$APK_DEBUG"
      else echo ""; fi
      ;;
    release) echo "$APK_RELEASE" ;;
    debug)   echo "$APK_DEBUG" ;;
    *)       echo "$sel" ;;
  esac
}

# Imprime "debug" o "release" según los artefactos dentro del APK desempaquetado.
apk_kind() {
  local work="$1"
  if [ -f "$work/assets/flutter_assets/kernel_blob.bin" ]; then
    echo "debug"
  elif ls "$work"/lib/*/libapp.so >/dev/null 2>&1; then
    echo "release"
  else
    echo "desconocido"
  fi
}
