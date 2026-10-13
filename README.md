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

| ID | Vulnerabilidad | Feature | Guía |
|----|----------------|---------|------|
| M1 | Improper Credential Usage | `lib/config/secrets.dart` | docs/01-M1-* |
| M2 | Inadequate Supply Chain Security | `vuln_bank/pubspec.yaml` | docs/02-M2-* |
| M3 | Insecure Authentication/Authorization | login + cuentas | docs/03-M3-* |
| M4 | Insufficient Input/Output Validation | búsqueda + deep link | docs/04-M4-* |
| M5 | Insecure Communication | capa HTTP + manifiestos | docs/05-M5-* |
| M6 | Inadequate Privacy Controls | perfil + logs | docs/06-M6-* |
| M7 | Insufficient Binary Protections | build release | docs/07-M7-* |
| M8 | Security Misconfiguration | AndroidManifest / Info.plist | docs/08-M8-* |
| M9 | Insecure Data Storage | SharedPreferences / SQLite | docs/09-M9-* |
| M10 | Insufficient Cryptography | `lib/core/crypto.dart` | docs/10-M10-* |

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
- [ ] Fase 1 — Esqueleto funcional seguro
- [ ] Fase 2 — Ramas `vuln/M1..M10`
- [ ] Fase 3 — Scripts + documentos
- [ ] Fase 4 — Ramas `fix/M1..M10`
