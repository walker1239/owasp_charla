/// Secretos y credenciales de la app.
///
/// [baseline] Aquí NO hay credenciales ni claves de servicio hardcodeadas: la
/// sesión se obtiene con el login del usuario (JWT firmado por el backend).
///
/// La rama `vuln/M1` añadirá en este punto una API key y credenciales de
/// servicio en texto plano, embebidas en el binario.
class Secrets {
  Secrets._();

  // Intencionalmente vacío en el baseline.
  //
  // Regla: los secretos NUNCA deben vivir en el código fuente. Se inyectan por
  // `--dart-define`, Keystore/Keychain, o se obtienen en tiempo de ejecución.
}
