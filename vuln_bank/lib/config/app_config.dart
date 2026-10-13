import 'dart:io';

/// Configuración de red de la app.
///
/// El baseline usa **HTTPS** contra el backend de desarrollo y fija el
/// certificado (ver `core/api_client.dart`). La rama `vuln/M5` desactivará esa
/// protección a propósito.
class AppConfig {
  AppConfig._();

  static const int port = 8443;

  /// Permite sobreescribir por línea de comandos:
  /// `flutter run --dart-define=API_BASE_URL=https://otro-host:8443`
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// En el emulador Android, `10.0.2.2` es el host del Mac.
  static String get host => Platform.isAndroid ? '10.0.2.2' : 'localhost';

  static String get baseUrl =>
      _override.isNotEmpty ? _override : 'https://$host:$port';
}
