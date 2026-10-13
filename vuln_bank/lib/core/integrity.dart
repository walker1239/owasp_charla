import 'dart:io';

/// Comprobaciones anti-root / anti-tamper.
///
/// [fix/M7] Detecta indicios de root (Android) o jailbreak (iOS) e
/// instrumentación, para poder bloquear o degradar la app en entornos
/// comprometidos. Complementa la ofuscación del build.
class Integrity {
  Integrity._();

  static const _rootPaths = [
    '/system/app/Superuser.apk',
    '/system/xbin/su',
    '/system/bin/su',
    '/sbin/su',
    '/data/local/xbin/su',
    '/data/local/bin/su',
    '/data/local/su',
    '/Applications/Cydia.app', // iOS (jailbreak)
    '/Library/MobileSubstrate',
  ];

  static Future<bool> isRootedOrJailbroken() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return false;
    for (final path in _rootPaths) {
      try {
        if (await File(path).exists()) return true;
      } catch (_) {
        // Sin permisos: se ignora.
      }
    }
    return false;
  }

  /// Heurística simple de instrumentación (Frida).
  static Future<bool> isInstrumented() async {
    if (!Platform.isAndroid) return false;
    try {
      final maps = await File('/proc/self/maps').readAsString();
      return maps.contains('frida') || maps.contains('gum-js-loop');
    } catch (_) {
      return false;
    }
  }
}
