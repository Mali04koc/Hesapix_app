import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:hesapix_app/services/auth_service.dart';

void main() {
  group('AuthService Testleri', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late AuthService authService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      authService = AuthService(db: fakeFirestore, auth: mockAuth);
    });

    test('login() başarılı olduğunda AuthUser döndürmeli', () async {
      const email = 'test@test.com';
      const password = 'password123';
      
      // Mock kullanıcı oluştur
      final user = MockUser(
        uid: 'uid123',
        email: email,
        displayName: 'Test User',
      );
      mockAuth = MockFirebaseAuth(mockUser: user);
      authService = AuthService(db: fakeFirestore, auth: mockAuth);

      // Firestore profilini oluştur
      await fakeFirestore.collection('kullanicilar').doc('uid123').set({
        'uid': 'uid123',
        'email': email,
        'ad_soyad': 'Test User',
        'rol': 'Admin',
        'aktif': true,
      });

      final authUser = await authService.login(
        usernameOrEmail: email,
        password: password,
      );

      expect(authUser.email, email);
      expect(authUser.role, 'Admin');
      expect(authUser.username, 'Test User');
    });

    test('Pasif kullanıcı giriş yapamamalı', () async {
      const email = 'pasif@test.com';
      const password = 'password123';
      
      final user = MockUser(
        uid: 'uid123',
        email: email,
      );
      mockAuth = MockFirebaseAuth(mockUser: user);
      authService = AuthService(db: fakeFirestore, auth: mockAuth);

      await fakeFirestore.collection('kullanicilar').doc('uid123').set({
        'uid': 'uid123',
        'email': email,
        'aktif': false,
        'rol': 'Admin',
      });

      expect(
        () => authService.login(usernameOrEmail: email, password: password),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('pasif'))),
      );
    });

    test('Boş bilgilerle hata vermeli', () async {
      expect(
        () => authService.login(usernameOrEmail: '', password: ''),
        throwsA(isA<AuthException>()),
      );
    });

    test('Firestore profili yoksa hata vermeli', () async {
      const email = 'orphan@test.com';
      final user = MockUser(uid: 'uid_orphan', email: email);
      mockAuth = MockFirebaseAuth(mockUser: user);
      authService = AuthService(db: fakeFirestore, auth: mockAuth);

      expect(
        () => authService.login(usernameOrEmail: email, password: 'pass'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('profili bulunamadı'),
          ),
        ),
      );
    });

    test('Kasiyer rolü ile giriş Kasiyer döndürmeli', () async {
      const email = 'kasiyer@test.com';
      final user = MockUser(uid: 'uid_k', email: email);
      mockAuth = MockFirebaseAuth(mockUser: user);
      authService = AuthService(db: fakeFirestore, auth: mockAuth);

      await fakeFirestore.collection('kullanicilar').doc('uid_k').set({
        'uid': 'uid_k',
        'email': email,
        'ad_soyad': 'Kasiyer User',
        'rol': 'Kasiyer',
        'aktif': true,
      });

      final authUser = await authService.login(
        usernameOrEmail: email,
        password: 'password123',
      );

      expect(authUser.role, 'Kasiyer');
    });
  });
}
