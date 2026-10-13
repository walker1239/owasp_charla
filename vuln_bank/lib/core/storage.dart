import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento del baseline — SEGURO.
///
/// Usa el almacén protegido por el sistema (Android Keystore / iOS Keychain)
/// en lugar de preferencias en claro.
///
/// La rama `vuln/M9` cambiará esto por `SharedPreferences` y SQLite sin cifrar.
class SecureStore {
  SecureStore._();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _tokenKey = 'auth_token';

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> readToken() => _storage.read(key: _tokenKey);

  static Future<void> clear() => _storage.deleteAll();
}
