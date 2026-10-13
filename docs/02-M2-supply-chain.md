# M2 — Inadequate Supply Chain Security

**Qué es:** dependencias desactualizadas, sin fijar o comprometidas que entran
en tu app a través del gestor de paquetes.

## Dónde está
- `vuln_bank/pubspec.yaml` → la rama `vuln/M2` deja versiones como `any` y fija
  dependencias antiguas.

## Cómo vulnerarlo
```bash
git checkout vuln/M2
./scripts/M2-supply-chain-audit.sh
```
El script:
1. `dart pub outdated` → versiones viejas.
2. Detecta constraints `any` (sin fijar).
3. Comprueba si `pubspec.lock` está versionado.
4. Consulta **OSV.dev** por CVEs de cada dependencia.

## Impacto
Una dependencia comprometida o con CVE ejecuta código en tu app (robo de datos,
backdoors) sin que toques tu propio código.

## Remediación (fix/M2)
- Fija versiones y versiona `pubspec.lock`.
- Escaneo SCA (OSV, `dart pub outdated`) en CI.
- Revisa el origen/permisos de cada paquete nuevo y usa un SBOM.
