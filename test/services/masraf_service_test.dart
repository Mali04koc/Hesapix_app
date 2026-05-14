import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hesapix_app/services/masraf_service.dart';
import 'package:hesapix_app/models/masraf_model.dart';

void main() {
  group('MasrafService Testleri', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MasrafService masrafService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      masrafService = MasrafService(db: fakeFirestore);
    });

    test('addMasraf() masrafı veritabanına eklemeli', () async {
      final masraf = Masraf(
        masrafId: 1,
        tip: 'kira',
        tutar: 1000.0,
        tarih: DateTime.now(),
        aciklama: 'Dükkan kirası',
      );

      await masrafService.addMasraf(masraf);

      final snapshot = await fakeFirestore.collection('masraflar').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['tip'], 'kira');
      expect(snapshot.docs.first.data()['tutar'], 1000.0);
    });

    test('getMasraflarByTip() sadece seçili tipteki masrafları getirmeli', () async {
      await fakeFirestore.collection('masraflar').add({
        'masraf_id': 1,
        'tip': 'elektrik',
        'tutar': 200.0,
        'tarih': DateTime.now().toIso8601String(),
        'aciklama': 'A',
      });
      await fakeFirestore.collection('masraflar').add({
        'masraf_id': 2,
        'tip': 'su',
        'tutar': 50.0,
        'tarih': DateTime.now().toIso8601String(),
        'aciklama': 'B',
      });

      final stream = masrafService.getMasraflarByTip('elektrik');
      final sonuclar = await stream.first;

      expect(sonuclar.length, 1);
      expect(sonuclar.first.tip, 'elektrik');
    });

    test('updateMasraf() masraf kaydını güncellemeli', () async {
      final docRef = await fakeFirestore.collection('masraflar').add({
        'tip': 'kira',
        'tutar': 1000.0,
        'tarih': DateTime.now().toIso8601String(),
      });

      final masraf = Masraf(
        id: docRef.id,
        masrafId: 1,
        tip: 'kira',
        tutar: 1100.0,
        tarih: DateTime.now(),
        aciklama: 'Zamlı kira',
      );

      await masrafService.updateMasraf(masraf);

      final snapshot = await docRef.get();
      expect(snapshot.data()!['tutar'], 1100.0);
      expect(snapshot.data()!['aciklama'], 'Zamlı kira');
    });
  });
}
