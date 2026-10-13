# M7 — Insufficient Binary Protections

**Qué es:** falta de ofuscación y de protecciones anti-root / anti-tamper,
lo que facilita la ingeniería inversa y el reempaquetado.

## Dónde está
- `vuln_bank/lib/**` → sin ofuscación; `vuln/M7` mantiene el release sin
  `--obfuscate`.
- No existe detección de root/jailbreak ni verificación de integridad/firma.

## Cómo vulnerarlo
```bash
git checkout vuln/M7
cd vuln_bank && flutter build apk --release
cd .. && ./scripts/M7-binary-repack.sh
```
El script:
1. `jadx` decompila y muestra el código (p. ej. `ApiClient`).
2. `apktool d` / `apktool b` reempaqueta el APK.
3. Revisa si hay `isRooted`/`frida`/`PlayIntegrity` (no los hay).

## Impacto
El binario se lee, modifica y redistribuye; el atacante puede saltar controles.

## Remediación (fix/M7)
- Build con `--obfuscate --split-debug-info`.
- R8/shrinking, verificación de firma e integridad.
- Detección de root/jailbreak y de instrumentación (Frida).
