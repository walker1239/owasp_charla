# M9 — Insecure Data Storage

**Qué es:** guardar datos sensibles sin cifrar o en ubicaciones accesibles
(SharedPreferences, SQLite, cache, almacenamiento externo).

## Dónde está
- `vuln_bank/lib/core/storage.dart` → baseline usa `flutter_secure_storage`
  (Keystore/Keychain). La rama `vuln/M9` lo cambia por `SharedPreferences`
  en claro y añade una tabla SQLite sin cifrar con datos de tarjetas.

## Cómo vulnerarlo
```bash
git checkout vuln/M9
cd vuln_bank && flutter run     # inicia sesión para guardar el token
cd .. && ./scripts/M9-storage-dump.sh
```
El script usa `adb shell run-as <pkg>` (funciona en builds debuggables) para:
- volcar `shared_prefs/FlutterSharedPreferences.xml` (token/email),
- extraer y leer `databases/*.db` con `sqlite3`.

## Impacto
Token de sesión y datos del usuario recuperables con acceso físico o backup.

## Remediación (fix/M9)
- `flutter_secure_storage` (Keystore/Keychain) para secretos.
- SQLCipher para bases locales; sin cache en almacenamiento externo.
- Cifrar cualquier dato sensible en reposo.
