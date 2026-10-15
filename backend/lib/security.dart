import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Utilidades de seguridad del baseline SEGURO.
///
/// El secreto JWT se lee del entorno; el baseline **verifica** la firma de cada
/// token. Las ramas `vuln/M3` rompen esta validación a propósito.
class Auth {
  Auth({String? secret})
      : _secret = secret ??
            const String.fromEnvironment(
              'JWT_SECRET',
              defaultValue: 'vulnbank-dev-secret-change-me',
            );

  final String _secret;

  String issueToken({required int userId, required String email}) {
    final jwt = JWT({'sub': userId, 'email': email});
    return jwt.sign(SecretKey(_secret), expiresIn: const Duration(hours: 1));
  }

  /// [M3] VULNERABLE: decodifica el token SIN verificar la firma.
  /// Permite forjar sesiones (incluido `alg: none`).
  JWT? verify(String? authorizationHeader) {
    if (authorizationHeader == null) return null;
    final token = authorizationHeader.startsWith('Bearer ')
        ? authorizationHeader.substring(7)
        : authorizationHeader;
    try {
      return JWT.decode(token);
    } on JWTException {
      return null;
    }
  }
}
