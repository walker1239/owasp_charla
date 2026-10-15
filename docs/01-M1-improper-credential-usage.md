# M1 — Improper Credential Usage

**Qué es:** credenciales, API keys o contraseñas de servicio embebidas en el
binario o el repositorio.

## Dónde está
- `vuln_bank/lib/config/secrets.dart` → la rama `vuln/M1` mete aquí
  `billingApiKey` y credenciales de servicio en texto plano.
- `vuln_bank/lib/core/api_client.dart` → las envía en la cabecera `X-API-Key`.
- `backend/bin/server.dart` → `/admin/users` está protegido con esa misma key.

## Cómo vulnerarlo (rápido, build debug)
```bash
git checkout vuln/M1
cd vuln_bank && flutter build apk --debug && cd ..
./scripts/M1-extract-secrets.sh debug
```

## Cómo vulnerarlo (realista, build RELEASE)
En un entorno real el atacante tiene el **release** (Play Store / APK mirror),
no el debug. El script soporta ambos:

```bash
git checkout vuln/M1
cd vuln_bank && flutter build apk --release && cd ..
./scripts/M1-extract-secrets.sh release
```

Y el remate — **release ofuscado** (`--obfuscate --split-debug-info`):

```bash
cd vuln_bank && flutter build apk --release --obfuscate --split-debug-info=build/symbols && cd ..
./scripts/M1-extract-secrets.sh release     # ¡el secreto SIGUE apareciendo!
```

El script (sin argumentos) usa **release si existe**, si no debug.

**Respuesta esperada:** aparece la API key y la contraseña de servicio
(extraídas de `kernel_blob.bin` en debug o de `libapp.so` en release):
```
sk_live_VLNBANK_9f8e7d6c5b4a3210
S3rv1c10-P@ss-2024
```

Y se usa la key extraída contra la API de administración:
```bash
curl -s --cacert backend/certs/ca.crt https://localhost:8443/admin/users \
  -H "X-API-Key: sk_live_VLNBANK_9f8e7d6c5b4a3210"
# => {"users":[{"id":1,"email":"ana@vulnbank.com", ...}, ...]}
```

## Debug vs Release (por qué el secreto no se protege con release)

| | Debug | Release |
|---|---|---|
| Compilación Dart | **JIT** | **AOT** |
| Dónde vive el código | `assets/flutter_assets/kernel_blob.bin` | `lib/<abi>/libapp.so` |
| Legibilidad | nombres de clases/funciones + literales | nativo, símbolos reducidos |
| Extraer el secreto | `grep`/`strings` | `strings`/`grep` (los **literales persisten**) |
| Con `--obfuscate` | — | cambian los nombres, **no los literales** |

**Conclusión:** un secreto hardcodeado tiene que estar en el binario para que la
app lo use ⇒ siempre es extraíble. La ofuscación (ver M7) sube el costo, no
elimina el secreto. Contra M1 sólo hay una defensa real: **no embeberlo**.

> 🔎 Herramientas avanzadas para release ofuscado: `blutter` y `reFlutter`
> reconstruyen nombres de clases/funciones desde `libapp.so`.

> ⚠️ **Release solo en ramas sin M8.** `vuln/M8` y `vuln/all` activan
> `android:debuggable="true"`, que Android **rechaza en release** por lint
> (`HardcodedDebugMode`). Para probar M1 en release usa `vuln/M1` (o cualquier
> rama que no incluya M8). Detalle en `docs/08-M8-misconfiguration.md`.

## Impacto
Cualquiera con el APK (release incluido) obtiene la credencial y puede llamar a
la API como el servicio.

## Remediación (fix/M1)
- No embebas secretos: `--dart-define`, Keystore/Keychain, o tokens efímeros.
- Rota cualquier credencial expuesta.
- En `fix/M1` la key se inyecta en build y va **vacía por defecto**.
