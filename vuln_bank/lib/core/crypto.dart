import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as c;
import 'package:pointycastle/export.dart';

/// Criptografía del baseline — implementaciones SEGURAS.
///
/// - Hash de integridad: SHA-256 (no MD5/SHA-1).
/// - Cifrado: AES-256-GCM (autenticado, IV aleatorio por operación).
/// - Aleatoriedad: `Random.secure()`.
///
/// La rama `vuln/M10` degradará esto a MD5, AES-ECB con IV fijo y clave
/// hardcodeada, además de `Random()` no seguro.
class Crypto {
  Crypto._();

  static Uint8List randomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => rnd.nextInt(256)));
  }

  static String sha256Hex(String input) =>
      c.sha256.convert(utf8.encode(input)).toString();

  /// Cifra con AES-256-GCM. Devuelve `iv || ciphertext(mac)`.
  static Uint8List aesGcmEncrypt(Uint8List key, Uint8List plain) {
    final iv = randomBytes(12);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    final out = cipher.process(plain);
    return Uint8List.fromList([...iv, ...out]);
  }

  static Uint8List aesGcmDecrypt(Uint8List key, Uint8List data) {
    final iv = data.sublist(0, 12);
    final body = data.sublist(12);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    return cipher.process(body);
  }
}
