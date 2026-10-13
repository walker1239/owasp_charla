#!/usr/bin/env bash
#
# VulnBank — instalación de herramientas de análisis y explotación.
# Uso: ./scripts/setup-tools.sh
#
set -euo pipefail

echo "==> VulnBank · setup de herramientas (OWASP Mobile Top 10)"
echo

if ! command -v brew >/dev/null 2>&1; then
  echo "[!] Homebrew no está instalado. Instálalo primero: https://brew.sh"
  exit 1
fi

echo "[*] Instalando herramientas base: jadx, apktool, mitmproxy ..."
brew install jadx apktool mitmproxy

echo
echo "[*] Instalando pipx (gestor de CLIs de Python) si falta ..."
if ! command -v pipx >/dev/null 2>&1; then
  brew install pipx
fi
pipx ensurepath

echo
echo "[*] Instalando frida-tools y objection ..."
pipx install frida-tools || pipx upgrade frida-tools
pipx install objection   || pipx upgrade objection

echo
echo "==> Verificación"
for t in adb emulator jadx apktool mitmproxy frida objection; do
  printf '  %-12s ' "$t"
  if command -v "$t" >/dev/null 2>&1; then echo "OK  ($(command -v "$t"))"; else echo "FALTA"; fi
done

echo
echo "Herramientas de Flutter/Android (deben venir del SDK de Flutter):"
for t in flutter dart; do
  printf '  %-12s ' "$t"
  if command -v "$t" >/dev/null 2>&1; then echo "OK  ($(command -v "$t"))"; else echo "FALTA"; fi
done

echo
echo "[✓] Listo. Si 'frida'/'objection' no aparecen, abre una nueva terminal (PATH de pipx)."
