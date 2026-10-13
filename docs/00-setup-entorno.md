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

## 2. Arrancar la app + backend

```bash
# Terminal 1 — backend inseguro
cd backend
dart run bin/server.dart            # escucha en http://localhost:8080

# Terminal 2 — emulador Android
flutter emulators --launch Pixel_6

# Terminal 3 — app
cd vuln_bank
flutter run
```

> Desde el emulador Android, `localhost` es el propio emulador. Para que la app
> alcance el backend del Mac usamos `adb reverse`:
>
> ```bash
> adb reverse tcp:8080 tcp:8080
> ```
> Así `http://localhost:8080` en el dispositivo apunta al backend del host.

## 3. Preparar el entorno de interceptación (M5)

```bash
mitmproxy -p 8081
```

Luego, en el emulador Android, apuntar el tráfico por el proxy:

```bash
# Arrancar el emulador con proxy (o usar el menú de red de Android Studio)
emulator -avd Pixel_6 -http-proxy http://10.0.2.2:8081
```

Instalar el certificado de mitmproxy como CA de usuario:

```bash
# Genera el .cer desde mitm.it en el navegador del emulador, o
# exporta el cert y súbelo:
adb push ~/.mitmproxy/mitmproxy-ca-cert.cer /sdcard/Download/
# Ajustes → Seguridad → Cifrado y credenciales → Instalar certificado → CA
```

> En Android 7+ las apps **solo confían en CAs de sistema** salvo que declaren lo
> contrario. En VulnBank lo habilitamos a propósito en las ramas `vuln/M5`.
> Instalar la CA a nivel de sistema requiere dispositivo rooteado o un
> `networkSecurityConfig` de usuario.

## 4. iOS (simulador)

- Ejecuta `flutter run` con el simulador abierto.
- Para interceptar, configura el proxy manualmente en
  *Ajustes → Wi-Fi → (i) → Proxy → Manual* apuntando a `127.0.0.1:8081`.
- `frida`/`objection` en simulador es limitado; el análisis dinámico completo
  requiere un dispositivo con jailbreak. Lo documentaremos en cada guía.

## 5. Estructura del repo

```
owasp/
├── vuln_bank/   # App Flutter
├── backend/     # API Dart/shelf insegura
├── docs/        # Guías por vulnerabilidad
├── scripts/     # Exploits + setup
└── README.md
```

## 6. Ramas

- `main` → baseline **seguro**.
- `vuln/Mx` → introduce la vulnerabilidad Mx.
- `fix/Mx` → corrige la vulnerabilidad Mx.
