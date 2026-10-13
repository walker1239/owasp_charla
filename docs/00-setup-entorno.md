# Fase 0 — Setup del entorno

Guía para dejar todo listo antes de empezar a vulnerar VulnBank.

## 1. Requisitos

| Herramienta | Para qué | Cómo |
|-------------|----------|------|
| Flutter 3.38+ / Dart 3.10+ | Compilar la app | ya instalado |
| Android SDK + emulador | Atacar Android | ya instalado (`Pixel_6`, `Medium_Phone_API_36`) |
| Xcode | Compilar/atacar iOS (simulador) | ya instalado |
| adb | Interactuar con el dispositivo | ya instalado |
| jadx, apktool, frida, objection, mitmproxy | Análisis estático/dinámico e interceptación | `./scripts/setup-tools.sh` |

Instala lo que falta:

```bash
./scripts/setup-tools.sh
```

## 2. Certificados TLS de desarrollo

El backend habla **HTTPS** con una CA propia; la app la **fija** (pinning).
Genera los certificados una sola vez:

```bash
./scripts/gen-certs.sh
```

Esto crea `backend/certs/{ca,server}.crt|key` y copia la CA al asset
`vuln_bank/assets/certs/ca.crt`. Volver a ejecutarlo regenera todo.

## 3. Arrancar backend + app

```bash
# Terminal 1 — backend HTTPS en https://localhost:8443
cd backend
dart run bin/server.dart

# Terminal 2 — emulador Android
flutter emulators --launch Pixel_6

# Terminal 3 — app
cd vuln_bank
flutter run
```

La app usa `https://10.0.2.2:8443` en Android (el `10.0.2.2` es el Mac visto
desde el emulador) y `https://localhost:8443` en iOS. Puedes forzar otra URL:

```bash
flutter run --dart-define=API_BASE_URL=https://mi-host:8443
```

> Alternativa para dispositivo físico Android: `adb reverse tcp:8443 tcp:8443`
> y usa `--dart-define=API_BASE_URL=https://localhost:8443`.

## 4. Interceptación (M5 — Insecure Communication)

En el baseline la app **fija** el certificado del backend: aunque pongas un
proxy, la conexión falla porque el certificado de mitmproxy no es el esperado.
Esa es precisamente la defensa que la rama `vuln/M5` desactiva.

Para preparar el ataque:

```bash
mitmproxy -p 8081
```

- **Android**: arranca el emulador apuntando al proxy
  ```bash
  emulator -avd Pixel_6 -http-proxy http://10.0.2.2:8081
  ```
  e instala la CA de mitmproxy como CA de usuario
  (exporta `~/.mitmproxy/mitmproxy-ca-cert.cer`, súbela con `adb push` a
  `/sdcard/Download/` e instálala desde *Ajustes → Seguridad*).
- **iOS (simulador)**: *Ajustes → Wi-Fi → (i) → Proxy → Manual* → `127.0.0.1:8081`.

Con `vuln/M5` activo verás el tráfico en claro; con `main` (baseline) la
conexión se rechaza. Esa diferencia es la lección.

## 5. iOS

- `flutter run` con el simulador abierto.
- `dart:io` valida el certificado con la CA fijada (el pinning es de la app,
  no depende de ATS). Por eso el baseline también falla ante mitmproxy.
- `frida`/`objection` en simulador es limitado; el análisis dinámico completo
  requiere jailbreak. Se documenta en cada guía.

## 6. Estructura del repo

```
owasp/
├── vuln_bank/   # App Flutter
├── backend/     # API Dart/shelf insegura (HTTPS dev)
├── docs/        # Guías por vulnerabilidad
├── scripts/     # Exploits + setup + gen-certs
└── README.md
```

## 7. Ramas

- `main` → baseline **seguro**.
- `vuln/Mx` → introduce la vulnerabilidad Mx.
- `fix/Mx` → corrige la vulnerabilidad Mx.
