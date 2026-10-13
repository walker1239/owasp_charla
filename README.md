# VulnBank — OWASP Mobile Top 10 (2024) en Flutter

App de banco **intencionalmente vulnerable** para practicar el OWASP Mobile
Top 10 (2024) uno por uno: **identificar → explotar → remediar**.

> ⚠️ Solo para uso educativo en un entorno controlado. Nunca expongas esto en
> producción.

## Componentes

| Carpeta | Qué es |
|---------|--------|
| `vuln_bank/` | App Flutter (Android + iOS) — el "banco" |
| `backend/` | API local en Dart/shelf, también insegura a propósito |
| `docs/` | Guías paso a paso por vulnerabilidad |
| `scripts/` | Exploits reproducibles y utilidades de setup |

## Empezar

```bash
./scripts/setup-tools.sh        # instala jadx/apktool/frida/objection/mitmproxy
./scripts/gen-certs.sh          # CA + cert del servidor (TLS del backend)

# Backend (HTTPS en https://localhost:8443)
cd backend && dart run bin/server.dart

# App (en otra terminal)
cd vuln_bank && flutter run
```

Detalles en [`docs/00-setup-entorno.md`](docs/00-setup-entorno.md).

## Top 10 (2024) y dónde vive cada fallo

| ID | Vulnerabilidad | Feature | Guía | Script |
|----|----------------|---------|------|--------|
| M1 | Improper Credential Usage | `lib/config/secrets.dart` | [01](docs/01-M1-improper-credential-usage.md) | `scripts/M1-extract-secrets.sh` |
| M2 | Inadequate Supply Chain Security | `vuln_bank/pubspec.yaml` | [02](docs/02-M2-supply-chain.md) | `scripts/M2-supply-chain-audit.sh` |
| M3 | Insecure Authentication/Authorization | login + cuentas | [03](docs/03-M3-auth.md) | `scripts/M3-bruteforce-idor.sh` |
| M4 | Insufficient Input/Output Validation | búsqueda + backend | [04](docs/04-M4-input-validation.md) | `scripts/M4-input-sqli.sh` |
| M5 | Insecure Communication | HTTP + manifiestos | [05](docs/05-M5-insecure-communication.md) | `scripts/M5-mitm-setup.sh` |
| M6 | Inadequate Privacy Controls | perfil + logs | [06](docs/06-M6-privacy.md) | `scripts/M6-privacy-leak.sh` |
| M7 | Insufficient Binary Protections | build release | [07](docs/07-M7-binary-protections.md) | `scripts/M7-binary-repack.sh` |
| M8 | Security Misconfiguration | AndroidManifest / Info.plist | [08](docs/08-M8-misconfiguration.md) | `scripts/M8-misconfig.sh` |
| M9 | Insecure Data Storage | SharedPreferences / SQLite | [09](docs/09-M9-data-storage.md) | `scripts/M9-storage-dump.sh` |
| M10 | Insufficient Cryptography | `lib/core/crypto.dart` | [10](docs/10-M10-cryptography.md) | `scripts/M10-crypto.sh` |

## Ramas

```
main            → baseline SEGURO (banco funcional)
vuln/M1…M10     → introduce SOLO la vulnerabilidad Mx
fix/M1…M10      → corrige la vulnerabilidad Mx
```

Flujo típico:

```bash
git checkout vuln/M3
./scripts/M3-bruteforce-idor.sh     # explotar
git checkout fix/M3
./scripts/M3-bruteforce-idor.sh     # verificar el fix
git diff vuln/M3 fix/M3             # la lección de remediación
```

## Estado

- [x] Fase 0 — Setup
- [x] Fase 1 — Esqueleto funcional seguro
- [x] Fase 2 — Ramas `vuln/M1..M10`
- [x] Fase 3 — Scripts + documentos
- [x] Fase 4 — Ramas `fix/M1..M10`

Todas las ramas existen: `vuln/M1..M10` y `fix/M1..M10`. Validadas en vivo:
M3 (IDOR/JWT/rate-limit) y M4 (SQLi) se bloquean en su `fix`.
