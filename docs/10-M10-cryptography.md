# M10 — Insufficient Cryptography

**Qué es:** algoritmos obsoletos (MD5/SHA-1, AES-ECB), IV fijo o reutilizado,
claves hardcodeadas y aleatoriedad no segura.

## Dónde está
- `vuln_bank/lib/core/crypto.dart` → baseline usa SHA-256 y AES-GCM con IV
  aleatorio y `Random.secure()`. La rama `vuln/M10` usa **MD5**, **AES-ECB**
  con IV fijo, clave hardcodeada `0123456789abcdef` y `Random()`.
- `backend/lib/database.dart` → `vuln/M10` cambia el hash de contraseñas a
  **MD5 sin salt**.

## Cómo vulnerarlo
```bash
git checkout vuln/M10
cd vuln_bank && flutter build apk --debug
cd .. && ./scripts/M10-crypto.sh
```
El script:
1. Extrae la clave hardcodeada y las referencias `AES/ECB`/`MD5` del APK.
2. Crackea un MD5 sin salt con un diccionario básico.
3. Demuestra que AES-ECB es determinista (bloques repetidos → mismo cifrado).

## Impacto
Claves recuperables y cifrado roto: sin confidencialidad ni integridad reales.

## Remediación (fix/M10)
- AES-GCM (autenticado) con IV aleatorio por operación.
- Claves en Keystore/Keychain, nunca en el código.
- PBKDF2/Argon2 para contraseñas con salt; `Random.secure()`.
