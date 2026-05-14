import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hesapix_app/services/satis_service.dart';
import 'package:hesapix_app/models/satis_detay_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('SatisService Testleri', () {
    late FakeFirebaseFirestore fakeFirestore;
    late SatisService satisService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      satisService = SatisService(db: fakeFirestore);
    });

    test('satisYap() başarılı olduğunda stok düşmeli ve bakiye artmalı', () async {
      // 1. Gerekli verileri oluştur
      final cariRef = fakeFirestore.collection('cariler').doc('c1');
      await cariRef.set({
        'cari_kodu': '123',
        'firma_adi': 'Test Firma',
        'vergi_no': '',
        'bakiye': 0.0,
      });

      final urunRef = fakeFirestore.collection('urunler').doc('u1');
      await urunRef.set({
        'urun_id': 1,
        'isim': 'Test Ürün',
        'stok': 10, // Başlangıç stoğu
      });

      final sepet = [
        SatisDetay(
          satisId: '',
          urunId: 'u1',
          urunAdi: 'Test Ürün',
          miktar: 2, // 2 adet satılacak
          birimFiyat: 100.0,
          kdvOrani: 18.0,
          araToplam: 200.0,
          kdvTutar: 36.0,
          toplam: 236.0,
        )
      ];

      // 2. Satış işlemini gerçekleştir (Tamamı açık hesap / borç)
      final satis = await satisService.satisYap(
        cariId: 'c1',
        araToplam: 200.0,
        kdvToplam: 36.0,
        iskonto: 0.0,
        genelToplam: 236.0,
        odemeTuru: 'Nakit',
        odenenTutar: 0.0, // Hiç ödenmedi, 236 TL borç olmalı
        kasiyerId: 'Admin',
        sepet: sepet,
      );

      expect(satis.faturaNo, isNotEmpty);
      
      // 3. Stokların güncellenmesini doğrula
      final urunDoc = await urunRef.get();
      expect(urunDoc.data()!['stok'], 8); // 10 - 2 = 8

      // 4. Cari bakiyesinin güncellenmesini doğrula
      final cariDoc = await cariRef.get();
      expect(cariDoc.data()!['bakiye'], 236.0); // Bakiye 236 arttı
      
      // 5. Cari hareketin eklendiğini doğrula
      final hareketler = await fakeFirestore.collection('cari_hareketler').where('cari_id', isEqualTo: 'c1').get();
      expect(hareketler.docs.length, 1);
      expect(hareketler.docs.first.data()['islem_tipi'], 'SATIS');
    });

    test('Stok yetersiz ise satisYap() hata fırlatmalı', () async {
      final cariRef = fakeFirestore.collection('cariler').doc('c1');
      await cariRef.set({'bakiye': 0.0});

      final urunRef = fakeFirestore.collection('urunler').doc('u1');
      await urunRef.set({'stok': 1}); // Sadece 1 adet var

      final sepet = [
        SatisDetay(satisId: '', urunId: 'u1', urunAdi: 'Test Ürün', miktar: 2, birimFiyat: 100, kdvOrani: 18, araToplam: 200, kdvTutar: 36, toplam: 236)
      ];

      expect(
        () async => await satisService.satisYap(
          cariId: 'c1', araToplam: 200, kdvToplam: 36, iskonto: 0, genelToplam: 236, odemeTuru: 'Nakit', odenenTutar: 0, kasiyerId: 'Admin', sepet: sepet,
        ),
        throwsException,
      );
    });
  });
}
