import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hesapix_app/services/cari_service.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';

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
  });
}
