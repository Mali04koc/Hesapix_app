import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hesapix_app/services/urun_service.dart';
import 'package:hesapix_app/models/urun_model.dart';

void main() {
  group('UrunService Testleri', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UrunService urunService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      urunService = UrunService(db: fakeFirestore);
    });

    test('addUrun() yeni ürün eklemeli ve urun_id atamalı', () async {
      final urun = Urun(
        urunId: 0,
        isim: 'Yeni Ürün',
        alisFiyat: 10,
        satisFiyat: 20,
        stok: 100,
        barkod: '123',
        gorsel: '',
        kategoriId: 'kat1',
        urunKodu: 'U1',
        tedarikciKodu: 'T1',
      );

      await urunService.addUrun(urun);

      final snapshot = await fakeFirestore.collection('urunler').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['urun_id'], 1);
      expect(snapshot.docs.first.data()['isim'], 'Yeni Ürün');
    });

    test('decreaseStock() stok miktarını azaltmalı', () async {
      final docRef = await fakeFirestore.collection('urunler').add({
        'urun_id': 1,
        'isim': 'Ürün',
        'stok': 10,
      });

      await urunService.decreaseStock(docRef.id, 3);

      final snapshot = await docRef.get();
      expect(snapshot.data()!['stok'], 7);
    });

    test('Yetersiz stok durumunda decreaseStock() hata fırlatmalı', () async {
      final docRef = await fakeFirestore.collection('urunler').add({
        'urun_id': 1,
        'isim': 'Ürün',
        'stok': 5,
      });

      expect(
        () => urunService.decreaseStock(docRef.id, 10),
        throwsException,
      );
    });

    test('urunAra() isim veya barkoda göre ürün bulmalı', () async {
      await fakeFirestore.collection('urunler').add({
        'urun_id': 1,
        'isim': 'Elma',
        'barkod': '111',
        'stok': 10,
        'alis_fiyat': 1,
        'satis_fiyat': 2,
        'kategori_id': 'k1',
        'urun_kodu': 'E1',
        'tedarikci_kodu': 'T1',
        'gorsel': '',
      });
      await fakeFirestore.collection('urunler').add({
        'urun_id': 2,
        'isim': 'Armut',
        'barkod': '222',
        'stok': 10,
        'alis_fiyat': 1,
        'satis_fiyat': 2,
        'kategori_id': 'k1',
        'urun_kodu': 'A1',
        'tedarikci_kodu': 'T1',
        'gorsel': '',
      });

      final sonuclar = await urunService.urunAra('elm');
      expect(sonuclar.length, 1);
      expect(sonuclar.first.isim, 'Elma');

      final sonuclar2 = await urunService.urunAra('222');
      expect(sonuclar2.length, 1);
      expect(sonuclar2.first.isim, 'Armut');
    });
  });
}
