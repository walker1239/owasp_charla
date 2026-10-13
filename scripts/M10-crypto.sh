#!/usr/bin/env bash
#
# M10 — Insufficient Cryptography
# Extrae la clave hardcodeada, crackea MD5 y demuestra ECB determinista.
#
# Rama: vuln/M10
# Uso:  ./scripts/M10-crypto.sh [ruta-al.apk]
#
set -euo pipefail
source "$(dirname "$0")/_common.sh"

APK="$(require_apk "${1:-$APK_DEBUG}")"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

bold "M10 · Insufficient Cryptography"
info "APK: $APK"
unzip -o -q "$APK" -d "$WORK"

bold "1) Extraer clave/clases criptográficas hardcodeadas"
grep -a -o -E "0123456789abcdef|AES/ECB|DES|MD5|md5|ECB" -r "$WORK" 2>/dev/null \
  | sort -u | head -20 | sed 's/^/  /' || true
if command -v strings >/dev/null 2>&1; then
  strings -a "$WORK/lib/arm64-v8a/libapp.so" 2>/dev/null \
    | grep -E "0123456789abcdef|AES/ECB" | sort -u | head | sed 's/^/  /' || true
fi

bold "2) Crackear un hash MD5 sin salt (diccionario básico)"
python3 - <<'PY'
import hashlib
targets = {
    "password123": hashlib.md5(b"password123").hexdigest(),
    "supersecreto": hashlib.md5(b"supersecreto").hexdigest(),
}
dictionary = ["123456","password","password123","admin","qwerty","supersecreto","hunter2"]
for clear in dictionary:
    h = hashlib.md5(clear.encode()).hexdigest()
    for label, tgt in targets.items():
        if h == tgt:
            print(f"  ✓ hash {h}  =>  '{clear}'")
PY
info "Con MD5 sin salt, el 'cracking' es casi instantáneo (rainbow tables)."

bold "3) AES-ECB es determinista (patrones repetidos = misma salida)"
python3 - <<'PY'
try:
    from Crypto.Cipher import AES
except Exception:
    AES = None
if AES is None:
    print("  (pycryptodome no instalado; demo teórica)")
    print("  AES-ECB(P='AAAA...AAAA') produce bloques de 16 bytes idénticos -> filtra patrones.")
else:
    key=b"0123456789abcdef"; c=AES.new(key, AES.MODE_ECB)
    block=b"A"*16
    print("  E(block)  =", c.encrypt(block).hex())
    print("  E(block)  =", c.encrypt(block).hex(), " <- idéntico => ECB")
PY

echo
bold "Impacto: claves recuperables y cifrado rompible (sin confidencialidad real)."
bold "Fix (fix/M10): AES-GCM con IV aleatorio, claves en Keystore, PBKDF2/Argon2, Random.secure()."
