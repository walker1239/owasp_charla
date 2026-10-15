import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../config/app_config.dart';
import '../config/secrets.dart';
import '../models/account.dart';
import '../models/beneficiary.dart';
import '../models/user.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

/// Cliente HTTP del baseline — SEGURO.
///
/// Confía **únicamente** en la CA de desarrollo de VulnBank (fijada desde el
/// asset `assets/certs/ca.crt`): cualquier otro certificado —por ejemplo el de
/// un proxy de interceptación— es rechazado. Esto es *certificate pinning*.
///
/// La rama `vuln/M5` lo cambiará por un cliente que acepta cualquier
/// certificado y tráfico en claro.
class ApiClient {
  ApiClient._(this._client);

  final http.Client _client;

  static Future<ApiClient> create() async {
    final caBytes = (await rootBundle.load('assets/certs/ca.crt'))
        .buffer
        .asUint8List();
    final context = SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificatesBytes(caBytes);
    final httpClient = HttpClient(context: context);
    return ApiClient._(IOClient(httpClient));
  }

  Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        // [fix/M1] La key se inyecta en build; si no se define, no se envía
        // (no hay secretos embebidos en el APK).
        if (Secrets.billingApiKey.isNotEmpty)
          'X-API-Key': Secrets.billingApiKey,
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    final res = await _client.get(_uri(path), headers: _headers(token));
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final res = await _client.post(
      _uri(path),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final Map<String, dynamic> data =
        res.body.isEmpty ? {} : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(
        res.statusCode,
        (data['error'] ?? 'error ${res.statusCode}').toString(),
      );
    }
    return data;
  }

  // --- endpoints ---------------------------------------------------------

  Future<({String token, User user})> login(String email, String password) async {
    final data = await post('/login', {'email': email, 'password': password});
    return (
      token: data['token'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<User> profile(String token) async {
    final data = await get('/profile', token: token);
    return User.fromJson(data);
  }

  Future<List<Account>> accounts(String token) async {
    final data = await get('/accounts', token: token);
    return [
      for (final a in data['accounts'] as List)
        Account.fromJson(a as Map<String, dynamic>)
    ];
  }

  Future<Account> account(String token, int id) async {
    final data = await get('/accounts/$id', token: token);
    return Account.fromJson(data);
  }

  Future<List<Transaction>> transactions(String token, int accountId) async {
    final data = await get('/accounts/$accountId/transactions', token: token);
    return [
      for (final t in data['transactions'] as List)
        Transaction.fromJson(t as Map<String, dynamic>)
    ];
  }

  Future<List<Beneficiary>> searchBeneficiaries(String token, String query) async {
    final data = await get(
      '/beneficiaries/search?q=${Uri.encodeQueryComponent(query)}',
      token: token,
    );
    return [
      for (final b in data['results'] as List)
        Beneficiary.fromJson(b as Map<String, dynamic>)
    ];
  }

  Future<double> transfer(
    String token, {
    required int fromAccountId,
    required String toAccountNumber,
    required double amount,
  }) async {
    final data = await post(
      '/transfer',
      {
        'from_account_id': fromAccountId,
        'to_account_number': toAccountNumber,
        'amount': amount,
      },
      token: token,
    );
    return (data['new_balance'] as num).toDouble();
  }
}
