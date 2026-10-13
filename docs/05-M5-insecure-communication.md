# M5 — Insecure Communication

**Qué es:** tráfico en claro o sin validar el certificado del servidor
(permite MITM).

## Dónde está
- `vuln_bank/lib/core/api_client.dart` → baseline fija la CA
  (`SecurityContext(withTrustedRoots:false)`). La rama `vuln/M5` lo cambia por
  `HttpClient()..badCertificateCallback = (_, __, ___) => true` (acepta
  cualquier certificado).
- `android/app/src/main/res/xml/network_security_config.xml` → `vuln/M5` pone
  `cleartextTrafficPermitted="true"` y `<certificates src="user"/>`.
- `ios/Runner/Info.plist` → `vuln/M5` añade `NSAllowsArbitraryLoads=true`.

## Cómo vulnerarlo
```bash
git checkout vuln/M5
./scripts/M5-mitm-setup.sh          # o con --run para arrancar mitmproxy
```
1. `mitmproxy -p 8081`.
2. Emulador con `-http-proxy http://10.0.2.2:8081` + CA de mitmproxy instalada
   como CA de usuario.
3. Inicia sesión en la app y observa el `POST /login` **en claro**.

En `main` la conexión se rechaza por el pinning (no ves el tráfico).

## Impacto
Robo de credenciales y manipulación de transferencias por un atacante en la red.

## Remediación (fix/M5)
- TLS obligatorio; `usesCleartextTraffic=false` y ATS estricto.
- **Certificate pinning** (CA fijada o fingerprint del certificado).
- No confiar en CAs instaladas por el usuario.
