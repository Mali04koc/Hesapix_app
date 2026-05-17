import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/utils/firestore_user_fields.dart';

void main() {
  group('readRoleFromData', () {
    test('standart rol alanını okur', () {
      expect(readRoleFromData({'rol': 'Admin'}), 'Admin');
    });

    test('büyük/küçük harf ve boşluklu anahtarı normalize eder', () {
      expect(readRoleFromData({' Rol ': 'Kasiyer'}), 'Kasiyer');
    });

    test('Türkçe ı/İ içeren anahtarı okur', () {
      expect(readRoleFromData({'Rol': 'Admin'}), 'Admin');
    });

    test('rol yoksa Kasiyer döner', () {
      expect(readRoleFromData({'email': 'a@b.com'}), 'Kasiyer');
    });

    test('rol anahtarı null ise boş string döner', () {
      expect(readRoleFromData({'rol': null}), '');
    });
  });

  group('isAdminRoleValue', () {
    test('Admin varyasyonlarını tanır', () {
      expect(isAdminRoleValue('Admin'), isTrue);
      expect(isAdminRoleValue(' admin '), isTrue);
      expect(isAdminRoleValue('ADMİN'), isTrue);
    });

    test('Kasiyer admin değildir', () {
      expect(isAdminRoleValue('Kasiyer'), isFalse);
      expect(isAdminRoleValue(''), isFalse);
    });
  });
}
