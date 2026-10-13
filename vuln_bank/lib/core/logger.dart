import 'package:flutter/foundation.dart';

/// Logger de la app.
///
/// [M6] VULNERABLE — registra PII y secretos en claro (visibles con
/// `adb logcat`). Ver `./scripts/M6-privacy-leak.sh`.
class Log {
  Log._();

  static void info(String message) {
    debugPrint('[VulnBank] $message');
  }

  /// Vuelca absolutamente todo, incluidos los datos sensibles.
  static void event(String action, {Map<String, Object?> sensitive = const {}}) {
    debugPrint('[VulnBank] $action $sensitive');
  }

  /// Registra credenciales completas (¡nunca hacer esto en producción!).
  static void credentials(String email, String password, String token) {
    debugPrint('[VulnBank] login email=$email password=$password token=$token');
  }
}
