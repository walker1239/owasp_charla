# M1 — Improper Credential Usage

**Qué es:** credenciales, API keys o contraseñas de servicio embebidas en el
binario o el repositorio.

## Dónde está
- `vuln_bank/lib/config/secrets.dart` → la rama `vuln/M1` mete aquí
  `billingApiKey` y credenciales de servicio en texto plano.
- `vuln_bank/lib/core/api_client.dart` → las envía en la cabecera `X-API-Key`.

## Cómo vulnerarlo
```bash
git checkout vuln/M1
cd vuln_bank && flutter build apk --debug
cd .. && ./scripts/M1-extract-secrets.sh
```
El script desempaqueta el APK y busca `sk_live_...` en `libapp.so`
(opcionalmente decompila con `jadx`).

Resultado esperado: aparece `sk_live_VLNBANK_9f8e7d6c5b4a3210` y la contraseña
de servicio. En `main` (baseline) no aparece nada.

## Impacto
Cualquiera con el APK obtiene la credencial y puede llamar a la API como el
servicio.

## Remediación (fix/M1)
- No embebas secretos: usa Keystore/Keychain o `--dart-define` en build.
- Rota cualquier credencial expuesta.
- Prefiere tokens efímeros emitidos en tiempo de ejecución.
