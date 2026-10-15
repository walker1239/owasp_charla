# M7 — Insufficient Binary Protections

**Qué es:** falta de ofuscación y de protecciones anti-root / anti-tamper,
lo que facilita la ingeniería inversa y el reempaquetado.

## Dónde está
- `android/app/build.gradle.kts` → `vuln/M7` deja `isMinifyEnabled=false`
  (sin reducción R8) y el build no usa `--obfuscate`.
- No existe detección de root/jailbreak ni verificación de integridad.

## ⚠️ Nota clave para Flutter (dónde mirar)
- **jadx** decompila la capa **Java/Kotlin** (envoltorio Android + plugins de
  Flutter). **Tu código Dart NO está ahí.**
- Tu Dart vive en **`lib/<abi>/libapp.so`** (AOT). Ahí se comprueba si los
  nombres de clases quedaron legibles (sin ofuscar) o no (ofuscado).

## Cómo vulnerarlo

### 1) Release SIN ofuscar (comportamiento de `vuln/M7`)
```bash
git checkout vuln/M7
cd vuln_bank && flutter build apk --release && cd ..
./scripts/M7-binary-repack.sh release
```
**Respuesta esperada** (paso 1):
```
✗ Símbolos de la app LEGIBLES → ApiClient AppState SecureStore VulnBankApp
  → NO está ofuscado (comportamiento de vuln/M7).
```

### 2) Release OFUSCADO (comportamiento de `fix/M7`)
```bash
cd vuln_bank && flutter build apk --release --obfuscate --split-debug-info=build/symbols && cd ..
./scripts/M7-binary-repack.sh release
```
**Respuesta esperada** (paso 1):
```
✓ Sin nombres de la app en libapp.so → código Dart OFUSCADO.
```
Y en el paso 5: `✓ Comprobaciones presentes (fix/M7 aplicado).`

## Qué comprueba el script (paso a paso)
1. **Capa Dart** (`libapp.so`): busca identificadores de la app
   (`ApiClient`, `SecureStore`, `AppState`, `VulnBankApp`, `LocalDb`) → si
   aparecen, **no** está ofuscada.
2. **Capa Java** (`jadx`): solo el envoltorio Android; recuerda que el Dart no
   está aquí.
3. **Reempaquetado** (`apktool d` / `apktool b`): re-firma con tu keystore.
4. **Gradle** (`build.gradle.kts`): `isMinifyEnabled` / `isShrinkResources`.
5. **Anti-root / anti-tamper**: busca `isRooted`/`isInstrumented`/`frida`/...

> 🔎 Herramientas avanzadas para reconstruir símbolos Dart de un release
> ofuscado: **`blutter`** y **`reFlutter`**.

## Impacto
Sin ofuscación/anti-tamper, el binario se lee, modifica y redistribuye con
facilidad; el atacante puede saltar controles.

## Remediación (fix/M7)
- Build con `--obfuscate --split-debug-info`, `isMinifyEnabled=true` (R8) y
  `isShrinkResources=true`.
- Detección de root/jailbreak y de instrumentación (Frida) — `lib/core/integrity.dart`.
- Verificación de firma/integridad.
- Ojo: la ofuscación **encarece** el ataque, no protege secretos (ver M1: los
  literales de string siguen visibles).
