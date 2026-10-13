import 'package:flutter_test/flutter_test.dart';
import 'package:vuln_bank/models/user.dart';

void main() {
  test('User.fromJson parsea el payload del backend', () {
    final u = User.fromJson({
      'id': 1,
      'name': 'Ana Torres',
      'email': 'ana@vulnbank.com',
      'role': 'customer',
    });
    expect(u.id, 1);
    expect(u.name, 'Ana Torres');
    expect(u.email, 'ana@vulnbank.com');
  });
}
