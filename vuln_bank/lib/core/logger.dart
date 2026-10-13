import 'package:flutter/foundation.dart';

/// Logger seguro del baseline.
///
/// [baseline] Nunca registra datos personales (PII), montos ni tokens.
/// La rama `vuln/M6` añadirá `print()` con PII a propósito.
class Log {
  Log._();

  static void info(String message) {
    if (kDebugMode) debugPrint('[VulnBank] $message');
  }

  /// Registra un evento censurando cualquier dato sensible.
  static void event(String action, {Map<String, Object?> sensitive = const {}}) {
    if (kDebugMode) {
      final keys = sensitive.keys.join(', ');
      debugPrint('[VulnBank] $action${keys.isEmpty ? '' : ' (datos ocultos: $keys)'}');
    }
  }
}
