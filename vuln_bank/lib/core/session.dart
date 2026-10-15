import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'api_client.dart';
import 'logger.dart';
import 'storage.dart';

/// Estado global de sesión.
///
/// [baseline] El token se guarda en almacenamiento seguro y no se registra.
class AppState extends ChangeNotifier {
  AppState(this.api);

  final ApiClient api;

  String? _token;
  User? _user;
  bool _restoring = true;

  String? get token => _token;
  User? get user => _user;
  bool get isLoggedIn => _token != null;
  bool get restoring => _restoring;

  /// Restaura la sesión guardada al arrancar.
  Future<void> bootstrap() async {
    final saved = await SecureStore.readToken();
    if (saved != null) {
      try {
        _user = await api.profile(saved);
        _token = saved;
      } catch (_) {
        await SecureStore.clear();
      }
    }
    _restoring = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final result = await api.login(email, password);
    _token = result.token;
    _user = result.user;
    await SecureStore.saveToken(result.token);
    // [M9] VULNERABLE: guarda credenciales y tarjeta SIN cifrar.
    await SecureStore.saveCredentials(email, password);
    await LocalDb.storeCard(
      number: '4111 1111 1111 1111',
      holder: result.user.name,
      cvv: '123',
    );
    // [M6] VULNERABLE: credenciales y token quedan en el logcat.
    Log.credentials(email, password, result.token);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await SecureStore.clear();
    notifyListeners();
  }
}
