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

## ⚙️ Nota de build (importante para la demo)
`vuln/M8` (y `vuln/all`) incluyen `android:debuggable="true"`, que Android
**rechaza en release** por lint:

```
AndroidManifest.xml: Error: Avoid hardcoding the debug mode … [HardcodedDebugMode]
> Lint found fatal errors while assembling a release target.
```

Es intencional: forma parte de la mala configuración (una app *debuggable* en
producción). Por eso, para la demo de M8 usa **debug** — y al exponer M8 deja
`android:debuggable="true"` en el manifiesto para mostrar el fallo:

```bash
git checkout vuln/M8
cd vuln_bank && flutter build apk --debug && cd ..
./scripts/M8-misconfig.sh
```

Si puntualmente necesitas un **release** en `vuln/all`, añade en
`android/app/build.gradle.kts`:

```kotlin
lint {
    checkReleaseBuilds = false
    abortOnError = false
}
```

## Impacto
Extracción de datos por backup, componentes expuestos y apps debuggables.

## Remediación (fix/M8)
- `android:allowBackup="false"` y reglas de `dataExtractionRules`.
- Componentes con `android:exported="false"` salvo lo imprescindible.
- Nunca `debuggable="true"` en release; ATS/Info.plist sin exposiciones.
