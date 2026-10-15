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
    // [fix/M3] Tokens de vida corta + emisor, además de verificar la firma.
    final jwt = JWT({'sub': userId, 'email': email, 'iss': 'vulnbank'});
    return jwt.sign(SecretKey(_secret), expiresIn: const Duration(minutes: 15));
  }

  /// Devuelve el payload si el token es válido, o `null` si no lo es.
  JWT? verify(String? authorizationHeader) {
    if (authorizationHeader == null) return null;
    final token = authorizationHeader.startsWith('Bearer ')
        ? authorizationHeader.substring(7)
        : authorizationHeader;
    try {
      return JWT.verify(token, SecretKey(_secret));
    } on JWTException {
      return null;
    }
  }
}
