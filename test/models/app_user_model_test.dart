import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hesapix_app/models/app_user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('AppUserModel Testleri', () {
    test('fromDoc() doğru nesne oluşturmalı', () async {
      final fakeDb = FakeFirebaseFirestore();
      
      final docRef = fakeDb.collection('users').doc('user1');
      final tarih = DateTime(2023, 1, 1);
      
      await docRef.set({
        'uid': 'uid123',
        'ad_soyad': 'Test Kullanıcı',
        'email': 'test@test.com',
        'rol': 'Admin',
        'aktif': true,
        'son_giris_tarihi': Timestamp.fromDate(tarih),
        'olusturulma_tarihi': Timestamp.fromDate(tarih),
      });

      final snapshot = await docRef.get();
      final userModel = AppUserModel.fromDoc(snapshot);

      expect(userModel.id, 'user1');
      expect(userModel.uid, 'uid123');
      expect(userModel.adSoyad, 'Test Kullanıcı');
      expect(userModel.email, 'test@test.com');
      expect(userModel.rol, 'Admin');
      expect(userModel.aktif, true);
      expect(userModel.sonGirisTarihi, tarih);
      expect(userModel.olusturulmaTarihi, tarih);
    });
  });
}
