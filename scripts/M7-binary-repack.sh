#!/usr/bin/env bash
#
# M7 — Insufficient Binary Protections
# Evalúa: símbolos Dart legibles vs ofuscados, reempaquetado y anti-tamper.
#
# IMPORTANTE (Flutter): tu código Dart NO está en las clases Java que lee jadx;
# vive en `lib/<abi>/libapp.so`. Ahí es donde se comprueba la ofuscación.
#
# Rama: vuln/M7   (sin ofuscación ni anti-tamper)
#       fix/M7    (R8 + --obfuscate + anti-root)
#
# Uso:  ./scripts/M7-binary-repack.sh [rutap.al.apk | release | debug]
#
set -euo pipefail
source "$(dirname "$0")/_common.sh"

APK="$(resolve_apk "${1:-auto}")"
if [ -z "${APK:-}" ] || [ ! -f "$APK" ]; then
  bold "M7 · Insufficient Binary Protections"
  bad "No hay APK para '${1:-auto}'."
  info "Compila release:"
  info "  sin ofuscación: (cd \"$ROOT/vuln_bank\" && flutter build apk --release)"
  info "  ofuscado:       (cd \"$ROOT/vuln_bank\" && flutter build apk --release --obfuscate --split-debug-info=build/symbols)"
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

bold "M7 · Insufficient Binary Protections"
info "APK: $APK"
info "Desempaquetando ..."
unzip -o -q "$APK" -d "$WORK"
info "Tipo: $(apk_kind "$WORK")"

# Identificadores Dart propios de la app: si aparecen, NO está ofuscada.
DART_SYMS='ApiClient|SecureStore|VulnBankApp|AppState|LocalDb|hashForIntegrity'

bold "1) Capa Dart (lib/*/libapp.so) — donde vive TU código Flutter"
if ls "$WORK"/lib/*/libapp.so >/dev/null 2>&1; then
  HITS="$(for so in "$WORK"/lib/*/libapp.so; do
    strings -a "$so" 2>/dev/null | grep -oE "$DART_SYMS" || true
  done | sort -u | tr '\n' ' ' | sed 's/ $//')"
  if [ -n "${HITS}" ]; then
    bad "Símbolos de la app LEGIBLES → $HITS"
    info "→ NO está ofuscado (comportamiento de vuln/M7)."
  else
    ok "Sin nombres de la app en libapp.so → código Dart OFUSCADO."
    info "→ En vuln/M7 verías: ApiClient, SecureStore, VulnBankApp..."
  fi
else
  info "No hay libapp.so → es un build DEBUG (JIT). Usa release para este análisis."
fi

bold "2) Capa Java/Android (jadx) — aquí NO está tu Dart"
if command -v jadx >/dev/null 2>&1; then
  jadx -q --no-res -d "$WORK/jadx" "$APK" >/dev/null 2>&1 || true
  info "jadx solo muestra el envoltorio Android y los plugins de Flutter."
  APPCLS="$(grep -rl "com/pragma/vulnbank" "$WORK/jadx/sources" 2>/dev/null | head -3 | sed "s#$WORK/jadx/sources/##" || true)"
  [ -n "$APPCLS" ] && info "Clases propias (envoltorio): $APPCLS" || info "Sin clases propias relevantes en el DEX."
else
  bad "jadx no instalado (./scripts/setup-tools.sh)."
fi

bold "3) Reempaquetado con apktool (posible si no hay anti-tamper real)"
if command -v apktool >/dev/null 2>&1; then
  apktool d -f -o "$WORK/decoded" "$APK" >/dev/null 2>&1 && ok "Decodificado en decoded/"
  apktool b "$WORK/decoded" -o "$WORK/repacked.apk" >/dev/null 2>&1 && ok "Reconstruido: repacked.apk"
  info "Re-firma con tu propio keystore e instálalo como actualización."
else
  bad "apktool no instalado (./scripts/setup-tools.sh)."
fi

bold "4) Ofuscación / reducción (android/app/build.gradle.kts)"
GRADLE="$ROOT/vuln_bank/android/app/build.gradle.kts"
grep -qE 'isMinifyEnabled[[:space:]]*=[[:space:]]*true' "$GRADLE" && ok "isMinifyEnabled = true (R8 activo)" || bad "isMinifyEnabled = false (sin reducción R8)"
grep -qE 'isShrinkResources[[:space:]]*=[[:space:]]*true' "$GRADLE" && ok "isShrinkResources = true" || bad "isShrinkResources = false"
info "La ofuscación Dart se aplica al compilar con: --obfuscate --split-debug-info=<dir>"

bold "5) Anti-root / anti-tamper"
if grep -rqE "isRooted|jailbreak|frida|SafetyNet|PlayIntegrity|isInstrumented" "$ROOT/vuln_bank/lib" 2>/dev/null; then
  ok "Comprobaciones presentes (fix/M7 aplicado)."
else
  bad "No hay detección de root/tampering ni verificación de integridad."
fi

echo
bold "Comparativa:  git diff vuln/M7 fix/M7"
bold "Impacto: sin ofuscación/anti-tamper, el binario se lee y reempaqueta libremente."
bold "Remediación (fix/M7): R8 + --obfuscate --split-debug-info, anti-root/tamper, verificación de firma."
