# M3 — Insecure Authentication / Authorization

**Qué es:** autenticación débil (sin límites) y autorización hecha en el
cliente o ausente en el servidor (IDOR).

## Dónde está
- `backend/bin/server.dart` → la rama `vuln/M3`:
  - elimina el **rate limiting** del login,
  - no **verifica la firma del JWT** (`JWT.decode` en vez de `JWT.verify`),
  - quita el **chequeo de propietario** en `/accounts/<id>` y `/transfer`.
- `vuln_bank/lib/features/accounts/*` → confía en el cliente para mostrar datos.

## Cómo vulnerarlo
```bash
git checkout vuln/M3
# backend corriendo
./scripts/M3-bruteforce-idor.sh
```
El script:
1. Prueba varias contraseñas → sin `429` (no hay bloqueo).
2. `GET /accounts/2001` con token de Ana → **200** (ve la cuenta de Luis = IDOR).
3. Forja un JWT (`alg:none`, `sub:3`) → `/profile` responde 200 (suplantación).

## Impacto
Acceso a cuentas ajenas, suplantación de identidad y fuerza bruta de credenciales.

## Remediación (fix/M3)
- Rate limiting y bloqueo por intentos.
- Verificar SIEMPRE la firma del JWT (`JWT.verify`).
- Autorización por propietario **en el servidor**, nunca solo en el cliente.
