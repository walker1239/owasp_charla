import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Almacenamiento local.
///
/// [M9] VULNERABLE — guarda datos sensibles SIN cifrar:
///   - `SharedPreferences`: token, email y contraseña en claro.
///   - SQLite (`vulnbank.db`): datos de tarjetas en claro.
///
/// Extraíble con `adb shell run-as <pkg> cat ...`
/// (ver `./scripts/M9-storage-dump.sh`).
class SecureStore {
  SecureStore._();

  static const _tokenKey = 'auth_token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token); // [M9] texto plano
  }

  static Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email); // [M9] PII en claro
    await prefs.setString('user_password', password); // [M9] ¡contraseña en claro!
  }

  static Future<String?> readToken() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  static Future<void> clear() async =>
      (await SharedPreferences.getInstance()).clear();
}

/// [M9] Base de datos SQLite local SIN cifrar, con datos de tarjetas.
class LocalDb {
  LocalDb._();

  static Future<void> storeCard({
    required String number,
    required String holder,
    required String cvv,
  }) async {
    final path = p.join(await getDatabasesPath(), 'vulnbank.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE cards ('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'number TEXT, holder TEXT, cvv TEXT)',
        );
      },
    );
    await db.insert('cards', {
      'number': number,
      'holder': holder,
      'cvv': cvv,
    });
    await db.close();
  }
}
