# M4 — Insufficient Input/Output Validation

**Qué es:** datos de entrada no validados que llegan a sinks peligrosos
(consultas SQL, HTML, rutas) y salida no saneada.

## Dónde está
- `backend/bin/server.dart` → `_searchBeneficiaries`: la rama `vuln/M4`
  construye la consulta **concatenando** el parámetro `q` (SQLi).
- El campo "Buscar beneficiario" de la app (`features/transfer/transfer_screen.dart`)
  es el vector.

## Cómo vulnerarlo
```bash
git checkout vuln/M4
./scripts/M4-input-sqli.sh
```
El script envía payloads:
- `' OR '1'='1` → devuelve todos los beneficiarios.
- `%' UNION SELECT id, email, password_hash, role FROM users --` → vuelca
  usuarios y hashes.

En `main` (consulta parametrizada) esos payloads devuelven vacío.

## Impacto
Lectura/escritura de toda la base de datos desde un campo de texto.

## Remediación (fix/M4)
- Consultas **parametrizadas** (placeholders `?`).
- Validación/allowlist de entrada y escapes de salida.
- Mínimo privilegio para el usuario de la base de datos.
