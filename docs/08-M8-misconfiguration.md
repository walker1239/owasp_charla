# M8 — Security Misconfiguration

**Qué es:** ajustes inseguros en manifiestos, backups, componentes exportados
o builds de depuración en producción.

## Dónde está
- `android/app/src/main/AndroidManifest.xml` → `vuln/M8` pone
  `android:allowBackup="true"` y `android:debuggable="true"`.
- `ios/Runner/Info.plist` → `vuln/M8` añade `UIFileSharingEnabled` y
  `LSSupportsOpeningDocumentsInPlace` (los datos de la app quedan visibles en
  la app Archivos).

## Cómo vulnerarlo
```bash
git checkout vuln/M8
cd vuln_bank && flutter build apk --debug
cd .. && ./scripts/M8-misconfig.sh
```
El script lee el manifiesto con `aapt2`, consulta los flags efectivos en el
dispositivo (`dumpsys package`) e intenta `adb backup` para extraer datos.

## Impacto
Extracción de datos por backup, componentes expuestos y apps debuggables.

## Remediación (fix/M8)
- `android:allowBackup="false"` y reglas de `dataExtractionRules`.
- Componentes con `android:exported="false"` salvo lo imprescindible.
- Nunca `debuggable="true"` en release; ATS/Info.plist sin exposiciones.
