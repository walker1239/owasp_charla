#!/usr/bin/env bash
#
# M2 — Inadequate Supply Chain Security
# Audita dependencias: desactualizadas, sin fijar y con CVEs conocidos (OSV).
#
# Rama: vuln/M2   (main mantiene versiones fijadas y actualizadas)
# Uso:  ./scripts/M2-supply-chain-audit.sh
#
set -euo pipefail
source "$(dirname "$0")/_common.sh"

APP="$ROOT/vuln_bank"
bold "M2 · Inadequate Supply Chain Security"

bold "1) Dependencias desactualizadas (dart pub outdated)"
( cd "$APP" && dart pub outdated --no-dev-dependencies 2>/dev/null | head -30 ) || \
  info "dart pub outdated no disponible."

bold "2) Constraint 'any' (versiones sin fijar = riesgo de cadena de suministro)"
grep -nE ':\s*any\s*$' "$APP/pubspec.yaml" && ok "Hay dependencias sin versión fija" || \
  info "Sin constraints 'any'."

bold "3) ¿Existe pubspec.lock versionado? (reproducibilidad)"
if git -C "$ROOT" ls-files --error-unmatch vuln_bank/pubspec.lock >/dev/null 2>&1; then
  ok "pubspec.lock versionado (build reproducible)."
else
  bad "pubspec.lock NO versionado: cada build puede traer versiones distintas."
fi

bold "4) CVEs conocidos por dependencia (OSV.dev)"
PKGS=$(python3 - "$APP/pubspec.lock" <<'PY'
import sys, re
text = open(sys.argv[1]).read()
for m in re.finditer(r'^  ([a-z0-9_]+):\n(?:.*\n)*?    version: "([^"]+)"', text, re.M):
    print(f"{m.group(1)}=={m.group(2)}")
PY
)
for pkg in $PKGS; do
  name="${pkg%%==*}"; ver="${pkg##*==}"
  resp=$(curl -s -X POST https://api.osv.dev/v1/query \
    -d "{\"package\":{\"name\":\"$name\",\"ecosystem\":\"Pub\"},\"version\":\"$ver\"}" 2>/dev/null || true)
  if echo "$resp" | grep -q '"id"'; then
    bad "$name $ver → CVE reportada:"
    echo "$resp" | python3 -c 'import sys,json; d=json.load(sys.stdin); [print("     -", v.get("id"), v.get("summary","")) for v in d.get("vulns",[])]' 2>/dev/null || true
  fi
done
info "Fin del escaneo OSV."

echo
bold "Impacto: una dependencia vieja/comprometida inyecta código en tu app."
bold "Fix (fix/M2): fija versiones, versiona pubspec.lock, escanea con OSV/SCA en CI."
