/// Secretos y credenciales de la app.
///
/// [fix/M1] Remediación: NO hay secretos embebidos en el binario.
///
/// La API key se inyecta en tiempo de build con `--dart-define` y por defecto
/// queda VACÍA (el APK no filtra credenciales):
///
///   flutter build apk --release --dart-define=BILLING_API_KEY=xxxx
///
/// En producción, además, se prefiere el Keystore/Keychain o tokens efímeros
/// emitidos en tiempo de ejecución en vez de una clave estática de servicio.
class Secrets {
  Secrets._();

  static const String billingApiKey = String.fromEnvironment('BILLING_API_KEY');
}
