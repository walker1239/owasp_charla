#!/usr/bin/env bash
#
# M1 — Improper Credential Usage
# Extrae credenciales/API keys hardcodeadas del APK.
#
# Funciona igual en DEBUG y en RELEASE (incluso ofuscado): un secreto embebido
# tiene que existir en el binario para que la app lo use, así que siempre es
# extraíble.
#
# Rama: vuln/M1   (en main esto NO encuentra nada)
#
# Uso:
#   ./scripts/M1-extract-secrets.sh              # release si existe, si no debug
#   ./scripts/M1-extract-secrets.sh release      # build release (realista)
#   ./scripts/M1-extract-secrets.sh debug
#   ./scripts/M1-extract-secrets.sh /ruta/app.apk
#
set -euo pipefail
source "$(dirname "$0")/_common.sh"

SEL="${1:-auto}"
APK="$(resolve_apk "$SEL")"

if [ -z "${APK:-}" ] || [ ! -f "$APK" ]; then
  bold "M1 · Improper Credential Usage"
  bad "No hay APK para '$SEL'."
  info "Compila uno:"
  info "  release (realista):  (cd \"$ROOT/vuln_bank\" && flutter build apk --release)"
  info "  release ofuscado:    (cd \"$ROOT/vuln_bank\" && flutter build apk --release --obfuscate --split-debug-info=build/symbols)"
  info "  debug:               (cd \"$ROOT/vuln_bank\" && flutter build apk --debug)"
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

bold "M1 · Improper Credential Usage"
info "APK: $APK"
info "Desempaquetando ..."
unzip -o -q "$APK" -d "$WORK"

KIND="$(apk_kind "$WORK")"
case "$KIND" in
  debug)   info "Tipo: DEBUG (JIT) → código Dart en assets/flutter_assets/kernel_blob.bin" ;;
  release) info "Tipo: RELEASE (AOT) → código Dart en lib/<abi>/libapp.so" ;;
  *)       info "Tipo: no identificado" ;;
esac

# Patrones de secretos hardcodeados de la rama vuln/M1.
PATTERNS='sk_live_[A-Za-z0-9_]+|S3rv1c10[^ "]*|svc-payments|VLNBANK'

bold "1) Extracción robusta de secretos (ASCII + UTF-16LE)"
FOUND=0
while IFS= read -r line; do
  ok "$line"
  FOUND=1
done < <(python3 - "$WORK" <<'PY'
import os, re, sys

root = sys.argv[1]
needles = [b"sk_live_", b"S3rv1c10", b"svc-payments", b"VLNBANK"]
seen = set()

def show(rel, enc, text):
    text = text.strip()
    key = (rel, text)
    if text and key not in seen:
        seen.add(key)
        print(f"{rel} [{enc}] {text}")

for dirpath, _, files in os.walk(root):
    for name in files:
        path = os.path.join(dirpath, name)
        try:
            data = open(path, "rb").read()
        except OSError:
            continue
        rel = os.path.relpath(path, root)
        for needle in needles:
            # ASCII
            idx = data.find(needle)
            if idx != -1:
                chunk = data[idx:idx + 60]
                txt = re.split(rb"[^A-Za-z0-9_.@:\-]", chunk)[0].decode("ascii", "ignore")
                show(rel, "ascii", txt)
            # UTF-16LE
            u = needle.decode().encode("utf-16-le")
            idx = data.find(u)
            if idx != -1:
                seg = data[idx:idx + 120]
                txt = seg.decode("utf-16-le", "ignore")
                txt = re.split(r"[^A-Za-z0-9_.@:\-]", txt)[0]
                show(rel, "utf16le", txt)
PY
)

if [ "$FOUND" -eq 0 ]; then
  bad "No se encontraron secretos hardcodeados (comportamiento del baseline)."
fi

bold "2) strings sobre libapp.so (el binario Dart de release/ofuscado)"
if ls "$WORK"/lib/*/libapp.so >/dev/null 2>&1; then
  for so in "$WORK"/lib/*/libapp.so; do
    abi="$(basename "$(dirname "$so")")"
    printf "  · %s/libapp.so\n" "$abi"
    strings -a "$so" 2>/dev/null | grep -E "$PATTERNS" | sort -u | head | sed 's/^/    /' || true
  done
  info "La ofuscación renombra símbolos, pero los literales de string siguen ahí."
else
  info "No hay libapp.so → es un build DEBUG (el código está en kernel_blob.bin)."
  info "Repite con release para ver este paso en acción."
fi

bold "3) (Opcional) Recuperar símbolos Dart de un release ofuscado"
if command -v blutter >/dev/null 2>&1; then
  info "blutter disponible: úsalo para reconstruir nombres desde libapp.so."
else
  info "Consejo: blutter / reFlutter recuperan clases y funciones de un libapp.so ofuscado."
fi

bold "4) (Informativo) jadx NO sirve para Dart"
info "jadx lee DEX/Java; los secretos de Flutter viven en el snapshot Dart, no en DEX."

echo
bold "Impacto: quien tenga el APK (release incluido) extrae la credencial y la usa contra la API."
bold "Fix (fix/M1): no embebas secretos; usa Keystore/Keychain, --dart-define o tokens efímeros."
