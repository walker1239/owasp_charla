import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

/// Capa de datos del backend de VulnBank.
///
/// El baseline (`main`) es SEGURO: contraseñas con salt + SHA-256 y consultas
/// parametrizadas. Las ramas `vuln/Mx` degradan estas defensas a propósito.
class Db {
  Db._(this.raw);

  final Database raw;

  /// Crea la base en memoria y la siembra con datos de ejemplo.
  factory Db.seed() {
    final db = sqlite3.openInMemory();

    db.execute('''
      CREATE TABLE users (
        id            INTEGER PRIMARY KEY,
        email         TEXT UNIQUE NOT NULL,
        name          TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        salt          TEXT NOT NULL,
        role          TEXT NOT NULL DEFAULT 'customer'
      );
    ''');
    db.execute('''
      CREATE TABLE accounts (
        id       INTEGER PRIMARY KEY,
        user_id  INTEGER NOT NULL,
        number   TEXT NOT NULL,
        balance  REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'PEN'
      );
    ''');
    db.execute('''
      CREATE TABLE beneficiaries (
        id             INTEGER PRIMARY KEY,
        user_id        INTEGER NOT NULL,
        alias          TEXT NOT NULL,
        account_number TEXT NOT NULL,
        bank           TEXT NOT NULL
      );
    ''');
    db.execute('''
      CREATE TABLE transactions (
        id         INTEGER PRIMARY KEY,
        account_id INTEGER NOT NULL,
        concept    TEXT NOT NULL,
        amount     REAL NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    // --- usuarios -------------------------------------------------------
    _insertUser(db, 1, 'ana@vulnbank.com', 'Ana Torres', 'password123');
    _insertUser(db, 2, 'luis@vulnbank.com', 'Luis Ramos', 'hunter2');
    _insertUser(db, 3, 'admin@vulnbank.com', 'Admin', 'supersecreto', role: 'admin');

    // --- cuentas --------------------------------------------------------
    _insertAccount(db, 1001, 1, '0011-0001-000001', 1500.50);
    _insertAccount(db, 1002, 1, '0011-0001-000002', 200.00);
    _insertAccount(db, 2001, 2, '0011-0002-000001', 9999.99);
    _insertAccount(db, 3001, 3, '0011-0003-000001', 50000.00);

    // --- beneficiarios --------------------------------------------------
    _insertBeneficiary(db, 1, 1, 'mama', '0011-9999-000123', 'BCP');
    _insertBeneficiary(db, 2, 1, 'jefe', '0011-8888-000456', 'Interbank');
    _insertBeneficiary(db, 3, 2, 'ahorros', '0011-7777-000789', 'BBVA');

    // --- movimientos ----------------------------------------------------
    _insertTransaction(db, 1, 1001, 'Sueldo', 3200.00);
    _insertTransaction(db, 2, 1001, 'Alquiler', -1200.00);
    _insertTransaction(db, 3, 1002, 'Cena', -85.50);
    _insertTransaction(db, 4, 2001, 'Ventas', 500.00);

    return Db._(db);
  }

  static void _insertUser(
    Database db,
    int id,
    String email,
    String name,
    String password, {
    String role = 'customer',
  }) {
    final salt = 'salt-$id-vulnbank';
    final hash = _hashPassword(password, salt);
    db.execute(
      'INSERT INTO users (id, email, name, password_hash, salt, role) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      [id, email, name, hash, salt, role],
    );
  }

  static void _insertAccount(
    Database db,
    int id,
    int userId,
    String number,
    double balance,
  ) {
    db.execute(
      'INSERT INTO accounts (id, user_id, number, balance, currency) '
      'VALUES (?, ?, ?, ?, ?)',
      [id, userId, number, balance, 'PEN'],
    );
  }

  static void _insertBeneficiary(
    Database db,
    int id,
    int userId,
    String alias,
    String accountNumber,
    String bank,
  ) {
    db.execute(
      'INSERT INTO beneficiaries (id, user_id, alias, account_number, bank) '
      'VALUES (?, ?, ?, ?, ?)',
      [id, userId, alias, accountNumber, bank],
    );
  }

  static void _insertTransaction(
    Database db,
    int id,
    int accountId,
    String concept,
    double amount,
  ) {
    db.execute(
      'INSERT INTO transactions (id, account_id, concept, amount, created_at) '
      'VALUES (?, ?, ?, ?, ?)',
      [id, accountId, concept, amount, DateTime.now().toIso8601String()],
    );
  }

  /// Hash de contraseña del baseline: salt + SHA-256.
  static String _hashPassword(String password, String salt) {
    // [M10] VULNERABLE: MD5 sin salt (crackeable con diccionario/rainbow tables).
    return md5.convert(password.codeUnits).toString();
  }

  /// Verifica una contraseña comparando hashes (implementación segura).
  bool verifyPassword(String email, String password) {
    final rows = raw.select(
      'SELECT password_hash, salt FROM users WHERE email = ?',
      [email],
    );
    if (rows.isEmpty) return false;
    final row = rows.first;
    final expected = _hashPassword(password, row['salt'] as String);
    return expected == row['password_hash'];
  }

  void close() => raw.close();
}
