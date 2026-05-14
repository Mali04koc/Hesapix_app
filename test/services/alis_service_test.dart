import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hesapix_app/services/alis_service.dart';
import 'package:hesapix_app/models/alis_detay_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('AlisService Testleri', () {
    late FakeFirebaseFirestore fakeFirestore;
    late AlisService alisService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      alisService = AlisService(db: fakeFirestore);
    });

    test('alisYap() başarılı olduğunda stok artmalı ve bakiye eksi yönde düşmeli', () async {
      // 1. Gerekli verileri oluştur
      final cariRef = fakeFirestore.collection('cariler').doc('c1');
      await cariRef.set({
        'cari_kodu': '123',
        'firma_adi': 'Tedarikçi',
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
        AlisDetay(
          alisId: '',
          urunId: 'u1',
          urunAdi: 'Test Ürün',
          miktar: 5, // 5 adet alınacak (stok 15 olmalı)
          birimFiyat: 100.0,
          kdvOrani: 18.0,
          araToplam: 500.0,
          kdvTutar: 90.0,
          toplam: 590.0,
        )
      ];

      // 2. Alış işlemini gerçekleştir (Tamamı Açık Hesap)
      final alis = await alisService.alisYap(
        cariId: 'c1',
        araToplam: 500.0,
        kdvToplam: 90.0,
        iskonto: 0.0,
        genelToplam: 590.0,
        odemeTuru: 'Açık Hesap',
        odenenTutar: 0.0, // Tamamı borç
        kasiyerId: 'Admin',
        sepet: sepet,
      );

      expect(alis.faturaNo, isNotEmpty);
      
      // 3. Stokların artmasını doğrula
      final urunDoc = await urunRef.get();
      expect(urunDoc.data()!['stok'], 15); // 10 + 5 = 15

      // 4. Cari bakiyesinin güncellenmesini doğrula (Alış işlemiyle bize borçlanılır, yani eksiye düşer)
      final cariDoc = await cariRef.get();
      expect(cariDoc.data()!['bakiye'], -590.0); // 0 - 590
      
      // 5. Cari hareketin eklendiğini doğrula
      final hareketler = await fakeFirestore.collection('cari_hareketler').where('cari_id', isEqualTo: 'c1').get();
      expect(hareketler.docs.length, 1);
      expect(hareketler.docs.first.data()['islem_tipi'], 'Alış Faturası (Borç)');
    });

    test('Tedarikçi seçilmezse alisYap() hata fırlatmalı', () async {
      final urunRef = fakeFirestore.collection('urunler').doc('u1');
      await urunRef.set({'stok': 10});

      final sepet = [
        AlisDetay(alisId: '', urunId: 'u1', urunAdi: 'Test Ürün', miktar: 5, birimFiyat: 100, kdvOrani: 18, araToplam: 500, kdvTutar: 90, toplam: 590)
      ];

      expect(
        () async => await alisService.alisYap(
          cariId: '', araToplam: 500, kdvToplam: 90, iskonto: 0, genelToplam: 590, odemeTuru: 'Nakit', odenenTutar: 590, kasiyerId: 'Admin', sepet: sepet,
        ),
        throwsException, // "Alış işlemlerinde tedarikçi seçimi zorunludur!"
      );
    });
  });
}
