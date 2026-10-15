/// Secretos y credenciales de la app.
///
/// [M1] VULNERABLE — credenciales y API key embebidas en el binario.
///
/// Extraíbles con `strings`/`jadx` sobre el APK:
///   ./scripts/M1-extract-secrets.sh
class Secrets {
  Secrets._();

  /// Clave de servicio usada para llamar a la API de administración.
  static const String billingApiKey = 'sk_live_VLNBANK_9f8e7d6c5b4a3210';

  /// Credenciales del servicio de pagos (texto plano).
  static const String serviceUser = 'svc-payments';
  static const String servicePassword = 'S3rv1c10-P@ss-2024';
}
