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

    test('updateUrun() ve deleteUrun() çalışmalı', () async {
      final docRef = await fakeFirestore.collection('urunler').add({
        'urun_id': 1,
        'isim': 'Eski',
        'stok': 5,
        'alis_fiyat': 1,
        'satis_fiyat': 2,
        'kategori_id': 'k1',
        'urun_kodu': 'U1',
        'tedarikci_kodu': '',
        'barkod': '',
        'gorsel': '',
      });

      await urunService.updateUrun(
        Urun(
          id: docRef.id,
          urunId: 1,
          isim: 'Yeni',
          alisFiyat: 1,
          satisFiyat: 2,
          stok: 5,
          barkod: '',
          gorsel: '',
          kategoriId: 'k1',
          urunKodu: 'U1',
          tedarikciKodu: '',
        ),
      );

      final updated = await docRef.get();
      expect(updated['isim'], 'Yeni');

      await urunService.deleteUrun(docRef.id);
      final deleted = await docRef.get();
      expect(deleted.exists, isFalse);
    });

    test('increaseStockByUrunId() stoku artırmalı', () async {
      await fakeFirestore.collection('urunler').add({
        'urun_id': 42,
        'isim': 'Stoklu',
        'stok': 10,
      });

      await urunService.increaseStockByUrunId(42, 5);

      final snap = await fakeFirestore
          .collection('urunler')
          .where('urun_id', isEqualTo: 42)
          .get();
      expect(snap.docs.first.data()['stok'], 15);
    });

    test('addUrun() ikinci üründe urun_id artmalı', () async {
      await fakeFirestore.collection('urunler').add({'urun_id': 5, 'isim': 'A', 'stok': 1});
      await urunService.addUrun(
        Urun(
          urunId: 0,
          isim: 'B',
          alisFiyat: 1,
          satisFiyat: 2,
          stok: 1,
          barkod: '',
          gorsel: '',
          kategoriId: 'k',
          urunKodu: '',
          tedarikciKodu: '',
        ),
      );

      final docs = await fakeFirestore.collection('urunler').orderBy('urun_id').get();
      expect(docs.docs.last.data()['urun_id'], 6);
    });

    test('getUrunler() stream ürün listesi döndürmeli', () async {
      await fakeFirestore.collection('urunler').add({'urun_id': 1, 'isim': 'X', 'stok': 1});
      final list = await urunService.getUrunler().first;
      expect(list.length, 1);
    });
  });
}
