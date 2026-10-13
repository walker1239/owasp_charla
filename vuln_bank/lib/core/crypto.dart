import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as c;
import 'package:pointycastle/export.dart';

/// Criptografía de la app.
///
/// [M10] VULNERABLE — implementaciones débiles:
///   - MD5 en lugar de SHA-256.
///   - AES-ECB con clave hardcodeada (sin IV, determinista).
///   - `Random()` en lugar de `Random.secure()`.
///
/// Ver `./scripts/M10-crypto.sh`.
class Crypto {
  Crypto._();

  /// [M10] Clave simétrica embebida en el binario (extraíble del APK).
  static const String hardcodedKey = '0123456789abcdef';

  static Uint8List randomBytes(int length) {
    // [M10] VULNERABLE: `Random()` no es criptográficamente seguro.
    final rnd = Random();
    return Uint8List.fromList(List<int>.generate(length, (_) => rnd.nextInt(256)));
  }

  /// [M10] VULNERABLE: MD5 (colisiones conocidas, sin salt).
  static String sha256Hex(String input) =>
      c.md5.convert(utf8.encode(input)).toString();

  /// Hash mostrado en la UI (integridad del perfil).
  static String hashForIntegrity(String input) => sha256Hex(input);

  /// [M10] VULNERABLE: AES-ECB con clave hardcodeada (sin IV).
  static Uint8List aesGcmEncrypt(Uint8List key, Uint8List plain) {
    final cipher = ECBBlockCipher(AESEngine())
      ..init(true, KeyParameter(Uint8List.fromList(utf8.encode(hardcodedKey))));
    return cipher.process(plain);
  }

  static Uint8List aesGcmDecrypt(Uint8List key, Uint8List data) {
    final cipher = ECBBlockCipher(AESEngine())
      ..init(false, KeyParameter(Uint8List.fromList(utf8.encode(hardcodedKey))));
    return cipher.process(data);
  }
}
