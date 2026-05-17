import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hesapix_app/services/cari_service.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';

import '../helpers/test_fixtures.dart';

void main() {
  group('CariService Testleri', () {
    late FakeFirebaseFirestore fakeFirestore;
    late CariService cariService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      cariService = CariService(db: fakeFirestore);
    });

    test('Yeni cari eklenebilmeli ve listelenebilmeli', () async {
      final cari = Cari(
        cariKodu: 'C001',
        firmaAdi: 'Test Firma',
        vergiNo: '1234567890',
        mail: 'test@test.com',
        adres: 'Adres',
        bakiye: 0.0,
      );

      await cariService.addCari(cari);

      final querySnapshot = await fakeFirestore.collection('cariler').get();
      expect(querySnapshot.docs.length, 1);
      expect(querySnapshot.docs.first['firma_adi'], 'Test Firma');
    });

    test('Cari hareket eklendiğinde bakiye doğru güncellenmeli (SATIS)', () async {
      // 1. Önce cari ekle
      final cari = Cari(
        cariKodu: 'C001',
        firmaAdi: 'Bakiye Test Firma',
        vergiNo: '',
        mail: '',
        adres: '',
        bakiye: 0.0,
      );
      final docRef = await fakeFirestore.collection('cariler').add(cari.toMap());
      final cariId = docRef.id;

      // 2. Satış hareketi ekle (bize borçlanıyor, bakiye artmalı)
      final hareket = CariHareket(
        cariId: cariId,
        islemTuru: 'Satış Faturası',
        evrakNo: 'FAT01',
        tutar: 500.0,
        tarih: DateTime.now(),
        islemTipi: 'SATIS',
        aciklama: 'Test Satış',
      );

      await cariService.addHareket(hareket);

      // 3. Bakiyeyi kontrol et
      final guncelCari = await fakeFirestore.collection('cariler').doc(cariId).get();
      expect(guncelCari['bakiye'], 500.0);
    });

    test('Cari hareket eklendiğinde bakiye doğru güncellenmeli (ODEME_AL)', () async {
      // 1. Önce cari ekle ve başlangıç bakiyesi ver
      final cari = Cari(
        cariKodu: 'C001',
        firmaAdi: 'Bakiye Test Firma',
        vergiNo: '',
        mail: '',
        adres: '',
        bakiye: 500.0,
      );
      final docRef = await fakeFirestore.collection('cariler').add(cari.toMap());
      final cariId = docRef.id;

      // 2. Ödeme alma hareketi ekle (borcu azalıyor, bakiye düşmeli)
      final hareket = CariHareket(
        cariId: cariId,
        islemTuru: 'Tahsilat',
        evrakNo: 'TAH01',
        tutar: 200.0,
        tarih: DateTime.now(),
        islemTipi: 'ODEME_AL',
        aciklama: 'Test Tahsilat',
      );

      await cariService.addHareket(hareket);

      // 3. Bakiyeyi kontrol et
      final guncelCari = await fakeFirestore.collection('cariler').doc(cariId).get();
      expect(guncelCari['bakiye'], 300.0);
    });

    test('cariAra() firma adına göre filtrelemeli', () async {
      await cariService.addCari(sampleCari(cariKodu: 'A1', firmaAdi: 'Acme Ltd'));
      await cariService.addCari(sampleCari(cariKodu: 'B1', firmaAdi: 'Beta A.Ş.'));

      final sonuc = await cariService.cariAra('acme');
      expect(sonuc.length, 1);
      expect(sonuc.first.firmaAdi, 'Acme Ltd');
    });

    test('updateCari() ve deleteCari() çalışmalı', () async {
      final cari = sampleCari(firmaAdi: 'Silinecek');
      final ref = await fakeFirestore.collection('cariler').add(cari.toMap());
      final id = ref.id;

      await cariService.updateCari(
        Cari(
          id: id,
          cariKodu: 'X1',
          firmaAdi: 'Güncellendi',
          vergiNo: '',
          mail: '',
          adres: '',
        ),
      );

      final updated = await fakeFirestore.collection('cariler').doc(id).get();
      expect(updated['firma_adi'], 'Güncellendi');

      await cariService.deleteCari(id);
      final deleted = await fakeFirestore.collection('cariler').doc(id).get();
      expect(deleted.exists, isFalse);
    });

    test('ODEME_YAP hareketi bakiyeyi artırmalı', () async {
      final docRef = await fakeFirestore.collection('cariler').add(
        sampleCari(bakiye: -500).toMap(),
      );
      final cariId = docRef.id;

      await cariService.addHareket(
        CariHareket(
          cariId: cariId,
          islemTuru: 'Ödeme',
          evrakNo: 'ODE01',
          tutar: 200.0,
          tarih: DateTime.now(),
          islemTipi: 'ODEME_YAP',
          aciklama: 'Tedarikçiye ödeme',
        ),
      );

      final guncel = await fakeFirestore.collection('cariler').doc(cariId).get();
      expect(guncel['bakiye'], -300.0);
    });

    test('cariAra() cari koduna göre bulmalı', () async {
      await cariService.addCari(sampleCari(cariKodu: 'OZEL01', firmaAdi: 'Firma X'));
      final sonuc = await cariService.cariAra('ozel');
      expect(sonuc.length, 1);
      expect(sonuc.first.cariKodu, 'OZEL01');
    });

    test('ALIS hareketi bakiyeyi düşürmeli', () async {
      final docRef = await fakeFirestore.collection('cariler').add(
        sampleCari(bakiye: 0).toMap(),
      );
      final cariId = docRef.id;

      await cariService.addHareket(
        CariHareket(
          cariId: cariId,
          islemTuru: 'Alış',
          evrakNo: 'AL1',
          tutar: 300.0,
          tarih: DateTime.now(),
          islemTipi: 'ALIS',
          aciklama: 'Alış borcu',
        ),
      );

      final guncel = await fakeFirestore.collection('cariler').doc(cariId).get();
      expect(guncel['bakiye'], -300.0);
    });

    test('getCariler() stream cari listesi döndürmeli', () async {
      await cariService.addCari(sampleCari(firmaAdi: 'Stream Test'));
      final list = await cariService.getCariler().first;
      expect(list.length, 1);
    });
  });
}
