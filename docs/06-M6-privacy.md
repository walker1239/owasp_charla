# M6 — Inadequate Privacy Controls

**Qué es:** exposición de PII/secretos por logs, permisos excesivos, clipboard,
capturas de pantalla o analítica.

## Dónde está
- `vuln_bank/lib/core/logger.dart` → `vuln/M6` añade `print()` con email,
  contraseña y token.
- `vuln_bank/lib/features/auth/login_screen.dart` y `core/session.dart` →
  registran credenciales.
- `android/app/src/main/AndroidManifest.xml` → permisos excesivos
  (`CAMERA`, `ACCESS_FINE_LOCATION`, `READ_CONTACTS`, `READ_SMS`).

## Cómo vulnerarlo
```bash
git checkout vuln/M6
cd vuln_bank && flutter run     # o instala el APK
cd .. && ./scripts/M6-privacy-leak.sh 20
```
El script limpia `logcat`, te pide usar la app y luego filtra líneas con PII.

Ejemplo de fuga esperada:
```
[VulnBank] login email=ana@vulnbank.com password=password123
```

## Impacto
PII y credenciales accesibles a otras apps, backups y sistemas MDM.

## Remediación (fix/M6)
- No loguear PII/secretos (usa `Log.event` que censura).
- Permisos mínimos y justificados.
- `FLAG_SECURE` para bloquear capturas; evitar clipboard sensible.
