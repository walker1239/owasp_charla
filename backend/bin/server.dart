import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart' show Row;

import 'package:backend/database.dart';
import 'package:backend/security.dart';

/// Backend de VulnBank — baseline SEGURO.
///
/// Aquí viven los endpoints que las ramas `vuln/Mx` degradarán:
///   M1 credenciales · M3 auth/authz · M4 validación/SQLi · M5 comunicación.
final db = Db.seed();
final auth = Auth();

/// Rate limiting de login (defensa que M3 elimina).
final Map<String, List<DateTime>> _loginAttempts = {};
const _maxAttempts = 5;
const _windowSeconds = 60;

final _router = Router()
  ..get('/', _root)
  ..post('/login', _login)
  ..get('/profile', _profile)
  ..get('/accounts', _accounts)
  ..get('/accounts/<id>', _accountById)
  ..get('/accounts/<id>/transactions', _transactions)
  ..get('/beneficiaries/search', _searchBeneficiaries)
  ..post('/transfer', _transfer);

void main(List<String> args) async {
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors)
      .addHandler(_router.call);

  // Certificados de desarrollo (genera con scripts/gen-certs.sh).
  final scriptDir = File(Platform.script.toFilePath()).parent.path;
  final certDir = Directory('$scriptDir/../certs').absolute.path;
  final context = SecurityContext()
    ..useCertificateChain('$certDir/server.crt')
    ..usePrivateKey('$certDir/server.key');

  final port = int.parse(Platform.environment['PORT'] ?? '8443');
  final server = await serve(
    handler,
    InternetAddress.anyIPv4,
    port,
    securityContext: context,
  );
  stdout.writeln('VulnBank backend (HTTPS) escuchando en https://localhost:${server.port}');
}

// --------------------------------------------------------------------------
// Middlewares y utilidades
// --------------------------------------------------------------------------

Middleware get _cors => (inner) => (req) async {
      if (req.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final res = await inner(req);
      return res.change(headers: _corsHeaders);
    };

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

Response _json(Object? body, {int status = 200}) => Response(
      status,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

Future<Map<String, dynamic>> _body(Request req) async {
  final text = await req.readAsString();
  if (text.isEmpty) return {};
  return jsonDecode(text) as Map<String, dynamic>;
}

/// Extrae el id de usuario autenticado o `null`.
int? _currentUserId(Request req) {
  final payload = auth.verify(req.headers['authorization']);
  if (payload == null) return null;
  return payload.payload is Map ? (payload.payload['sub'] as num?)?.toInt() : null;
}

// --------------------------------------------------------------------------
// Handlers
// --------------------------------------------------------------------------

Response _root(Request req) => _json({'service': 'vulnbank', 'status': 'ok'});

Future<Response> _login(Request req) async {
  final data = await _body(req);
  final email = data['email'] as String? ?? '';
  final password = data['password'] as String? ?? '';

  // [baseline] Rate limiting por email.
  final now = DateTime.now();
  final attempts = (_loginAttempts[email] ?? [])
      .where((t) => now.difference(t).inSeconds < _windowSeconds)
      .toList();
  if (attempts.length >= _maxAttempts) {
    return _json({'error': 'demasiados intentos, espera un momento'}, status: 429);
  }

  if (!db.verifyPassword(email, password)) {
    attempts.add(now);
    _loginAttempts[email] = attempts;
    return _json({'error': 'credenciales inválidas'}, status: 401);
  }

  _loginAttempts.remove(email);
  final rows = db.raw.select('SELECT id, name FROM users WHERE email = ?', [email]);
  final user = rows.first;
  final token = auth.issueToken(
    userId: user['id'] as int,
    email: email,
  );
  return _json({
    'token': token,
    'user': {'id': user['id'], 'name': user['name'], 'email': email},
  });
}

Response _profile(Request req) {
  final userId = _currentUserId(req);
  if (userId == null) return _json({'error': 'no autorizado'}, status: 401);

  final rows = db.raw.select(
    'SELECT id, email, name, role FROM users WHERE id = ?',
    [userId],
  );
  if (rows.isEmpty) return _json({'error': 'no encontrado'}, status: 404);
  final row = rows.first;
  return _json({
    'id': row['id'],
    'email': row['email'],
    'name': row['name'],
    'role': row['role'],
  });
}

Response _accounts(Request req) {
  final userId = _currentUserId(req);
  if (userId == null) return _json({'error': 'no autorizado'}, status: 401);

  final rows = db.raw.select(
    'SELECT id, number, balance, currency FROM accounts WHERE user_id = ?',
    [userId],
  );
  return _json({'accounts': [for (final r in rows) _accountToMap(r)]});
}

Response _accountById(Request req, String id) {
  final userId = _currentUserId(req);
  if (userId == null) return _json({'error': 'no autorizado'}, status: 401);

  final rows = db.raw.select(
    'SELECT id, user_id, number, balance, currency FROM accounts WHERE id = ?',
    [int.tryParse(id) ?? -1],
  );
  if (rows.isEmpty) return _json({'error': 'no encontrado'}, status: 404);

  // [baseline] Authorization en el SERVIDOR: solo el dueño puede verla.
  if (rows.first['user_id'] != userId) {
    return _json({'error': 'prohibido'}, status: 403);
  }
  return _json(_accountToMap(rows.first));
}

Response _transactions(Request req, String id) {
  final userId = _currentUserId(req);
  if (userId == null) return _json({'error': 'no autorizado'}, status: 401);

  final owner = db.raw.select(
    'SELECT user_id FROM accounts WHERE id = ?',
    [int.tryParse(id) ?? -1],
  );
  if (owner.isEmpty) return _json({'error': 'no encontrado'}, status: 404);
  if (owner.first['user_id'] != userId) {
    return _json({'error': 'prohibido'}, status: 403);
  }

  final rows = db.raw.select(
    'SELECT id, concept, amount, created_at FROM transactions WHERE account_id = ?',
    [int.tryParse(id) ?? -1],
  );
  return _json({
    'transactions': [
      for (final r in rows)
        {
          'id': r['id'],
          'concept': r['concept'],
          'amount': r['amount'],
          'created_at': r['created_at'],
        }
    ]
  });
}

Response _searchBeneficiaries(Request req) {
  final userId = _currentUserId(req);
  if (userId == null) return _json({'error': 'no autorizado'}, status: 401);

  final q = req.url.queryParameters['q'] ?? '';
  // [baseline] Consulta PARAMETRIZADA (inmune a SQLi).
  final rows = db.raw.select(
    'SELECT id, alias, account_number, bank FROM beneficiaries '
    'WHERE user_id = ? AND alias LIKE ?',
    [userId, '%$q%'],
  );
  return _json({
    'results': [
      for (final r in rows)
        {
          'id': r['id'],
          'alias': r['alias'],
          'account_number': r['account_number'],
          'bank': r['bank'],
        }
    ]
  });
}

Future<Response> _transfer(Request req) async {
  final userId = _currentUserId(req);
  if (userId == null) return _json({'error': 'no autorizado'}, status: 401);

  final data = await _body(req);
  final fromId = (data['from_account_id'] as num?)?.toInt();
  final toNumber = data['to_account_number'] as String? ?? '';
  final amount = (data['amount'] as num?)?.toDouble() ?? 0;

  if (fromId == null || amount <= 0) {
    return _json({'error': 'datos inválidos'}, status: 400);
  }

  final origin = db.raw.select(
    'SELECT id, user_id, balance FROM accounts WHERE id = ?',
    [fromId],
  );
  if (origin.isEmpty) return _json({'error': 'cuenta origen no existe'}, status: 404);
  // [baseline] Solo puedes transferir DESDE tus propias cuentas.
  if (origin.first['user_id'] != userId) {
    return _json({'error': 'prohibido'}, status: 403);
  }
  final balance = origin.first['balance'] as double;
  if (balance < amount) return _json({'error': 'saldo insuficiente'}, status: 400);

  db.raw.execute('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount, fromId]);
  db.raw.execute('UPDATE accounts SET balance = balance + ? WHERE number = ?', [amount, toNumber]);
  db.raw.execute(
    'INSERT INTO transactions (account_id, concept, amount, created_at) VALUES (?, ?, ?, ?)',
    [fromId, 'Transferencia a $toNumber', -amount, DateTime.now().toIso8601String()],
  );

  return _json({'status': 'ok', 'new_balance': balance - amount});
}

Map<String, dynamic> _accountToMap(Row r) => {
      'id': r['id'],
      'number': r['number'],
      'balance': r['balance'],
      'currency': r['currency'],
    };
