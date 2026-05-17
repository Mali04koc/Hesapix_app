import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/services/session_service.dart';
import 'package:hesapix_app/models/auth_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SessionService Testleri', () {
    late SessionService sessionService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sessionService = SessionService();
    });

    test('save() rememberMe true ise verileri kaydetmeli', () async {
      const user = AuthUser(id: '1', username: 'Test', email: 'test@test.com', role: 'Admin');
      
      await sessionService.save(user, rememberMe: true);

      final readUser = await sessionService.read();
      expect(readUser, isNotNull);
      expect(readUser!.username, 'Test');
    });

    test('save() rememberMe false ise verileri temizlemeli (read null dönmeli)', () async {
      const user = AuthUser(id: '1', username: 'Test', email: 'test@test.com', role: 'Admin');
      
      await sessionService.save(user, rememberMe: false);

      final readUser = await sessionService.read();
      expect(readUser, isNull);
    });

    test('getLastUser() son giren kullanıcıyı dönmeli', () async {
      const user = AuthUser(id: '1', username: 'Test', email: 'test@test.com', role: 'Admin');
      await sessionService.save(user, rememberMe: false);

      final lastUser = await sessionService.getLastUser();
      expect(lastUser!['email'], 'test@test.com');
    });

    test('clear() verileri temizlemeli', () async {
      const user = AuthUser(id: '1', username: 'Test', email: 'test@test.com', role: 'Admin');
      await sessionService.save(user, rememberMe: true);
      
      await sessionService.clear();
      
      final readUser = await sessionService.read();
      expect(readUser, isNull);
    });

    test('forgetLastUser() son kullanıcı bilgisini temizlemeli', () async {
      const user = AuthUser(id: '1', username: 'Test', email: 'test@test.com', role: 'Admin');
      await sessionService.save(user, rememberMe: false);

      await sessionService.forgetLastUser();

      final last = await sessionService.getLastUser();
      expect(last, isNull);
    });
  });
}
