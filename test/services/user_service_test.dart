import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:hesapix_app/services/auth_service.dart';
import 'package:hesapix_app/services/user_service.dart';

import '../helpers/test_fixtures.dart';

void main() {
  group('UserService Testleri', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late UserService userService;

    const adminId = 'admin1';
    const adminEmail = 'admin@test.com';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      userService = UserService(db: fakeFirestore, auth: mockAuth);
    });

    Future<void> seedTwoAdmins() async {
      await seedKullanici(
        fakeFirestore,
        id: adminId,
        email: adminEmail,
        adSoyad: 'Ana Admin',
      );
      await seedKullanici(
        fakeFirestore,
        id: 'admin2',
        email: 'admin2@test.com',
        adSoyad: 'Yedek Admin',
      );
    }

    test('updateUser() kullanıcı bilgilerini güncellemeli', () async {
      await seedTwoAdmins();
      await seedKullanici(
        fakeFirestore,
        id: 'kasiyer1',
        email: 'kasiyer@test.com',
        rol: 'Kasiyer',
      );

      await userService.updateUser(
        userId: 'kasiyer1',
        adSoyad: 'Güncel Ad',
        email: 'kasiyer@test.com',
        rol: 'Kasiyer',
        aktif: true,
        currentAdminId: adminId,
      );

      final doc = await fakeFirestore.collection('kullanicilar').doc('kasiyer1').get();
      expect(doc['ad_soyad'], 'Güncel Ad');
    });

    test('updateUser() bulunamayan kullanıcıda hata vermeli', () async {
      await seedTwoAdmins();

      expect(
        () => userService.updateUser(
          userId: 'yok',
          adSoyad: 'X',
          email: 'x@test.com',
          rol: 'Kasiyer',
          aktif: true,
          currentAdminId: adminId,
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('bulunamadı'))),
      );
    });

    test('updateUser() duplicate e-postada hata vermeli', () async {
      await seedTwoAdmins();
      await seedKullanici(
        fakeFirestore,
        id: 'kasiyer1',
        email: 'kasiyer@test.com',
        rol: 'Kasiyer',
      );

      expect(
        () => userService.updateUser(
          userId: 'kasiyer1',
          adSoyad: 'X',
          email: adminEmail,
          rol: 'Kasiyer',
          aktif: true,
          currentAdminId: adminId,
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('e-posta'))),
      );
    });

    test('updateUser() admin kendi rolünü kasiyer yapamaz', () async {
      await seedTwoAdmins();

      expect(
        () => userService.updateUser(
          userId: adminId,
          adSoyad: 'Ana Admin',
          email: adminEmail,
          rol: 'Kasiyer',
          aktif: true,
          currentAdminId: adminId,
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('kasiyer'))),
      );
    });

    test('updateUser() son aktif admin pasifleştirilemez', () async {
      await seedKullanici(fakeFirestore, id: adminId, email: adminEmail);

      expect(
        () => userService.updateUser(
          userId: adminId,
          adSoyad: 'Ana Admin',
          email: adminEmail,
          rol: 'Admin',
          aktif: false,
          currentAdminId: adminId,
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('admin'))),
      );
    });

    test('deleteUser() admin kendi hesabını silemez', () async {
      await seedTwoAdmins();

      expect(
        () => userService.deleteUser(userId: adminId, currentAdminId: adminId),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('silemez'))),
      );
    });

    test('deleteUser() kasiyeri silebilmeli', () async {
      await seedTwoAdmins();
      await seedKullanici(
        fakeFirestore,
        id: 'kasiyer1',
        email: 'kasiyer@test.com',
        rol: 'Kasiyer',
      );

      await userService.deleteUser(userId: 'kasiyer1', currentAdminId: adminId);

      final doc = await fakeFirestore.collection('kullanicilar').doc('kasiyer1').get();
      expect(doc.exists, isFalse);
    });

    test('deleteUser() son aktif admin silinemez', () async {
      await seedKullanici(fakeFirestore, id: adminId, email: adminEmail);

      expect(
        () => userService.deleteUser(userId: adminId, currentAdminId: 'other'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('admin'))),
      );
    });

    test('setUserActive() admin kendini pasife alamaz', () async {
      await seedTwoAdmins();

      expect(
        () => userService.setUserActive(
          userId: adminId,
          aktif: false,
          currentAdminId: adminId,
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('pasife'))),
      );
    });

    test('setUserActive() kasiyeri pasife alabilmeli', () async {
      await seedTwoAdmins();
      await seedKullanici(
        fakeFirestore,
        id: 'kasiyer1',
        email: 'kasiyer@test.com',
        rol: 'Kasiyer',
      );

      await userService.setUserActive(
        userId: 'kasiyer1',
        aktif: false,
        currentAdminId: adminId,
      );

      final doc = await fakeFirestore.collection('kullanicilar').doc('kasiyer1').get();
      expect(doc['aktif'], isFalse);
    });

    test('createUser() Firestore\'da kayıtlı e-postada hata vermeli', () async {
      await seedKullanici(
        fakeFirestore,
        id: 'existing',
        email: 'dup@test.com',
      );

      expect(
        () => userService.createUser(
          adSoyad: 'Yeni',
          email: 'dup@test.com',
          password: 'Sifre123!',
          rol: 'Kasiyer',
          aktif: true,
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('zaten var'))),
      );
    });

    test('streamUsers() kullanıcı listesi döndürmeli', () async {
      await seedTwoAdmins();
      await seedKullanici(
        fakeFirestore,
        id: 'kasiyer1',
        email: 'kasiyer@test.com',
        rol: 'Kasiyer',
      );

      final users = await userService.streamUsers().first;
      expect(users.length, 3);
    });
  });
}
