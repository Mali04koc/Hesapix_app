import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/models/auth_user.dart';

void main() {
  group('AuthUser Modeli Testleri', () {
    test('Özellikler doğru atanmalı', () {
      const user = AuthUser(
        id: '1',
        username: 'Test User',
        email: 'test@test.com',
        role: 'Admin',
      );

      expect(user.id, '1');
      expect(user.username, 'Test User');
      expect(user.email, 'test@test.com');
      expect(user.role, 'Admin');
    });
  });
}
