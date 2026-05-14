import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hesapix_app/services/rapor_service.dart';
import 'package:hesapix_app/models/satis_model.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';

void main() {
  group('RaporService Testleri', () {
    late FakeFirebaseFirestore fakeFirestore;
    late RaporService raporService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      raporService = RaporService(db: fakeFirestore);
    });

    test('getSatislar() belirtilen tarih aralığındaki satışları getirmeli', () async {
      final bugun = DateTime.now();
      final gecenAy = bugun.subtract(const Duration(days: 30));

      final satis1 = Satis(
        cariId: 'c1',
        tarih: bugun,
        faturaNo: 'F1',
        araToplam: 100, kdvToplam: 18, iskonto: 0, genelToplam: 118,
        odemeTuru: 'Nakit', odenenTutar: 118, kasiyerId: '1',
      );
      final satis2 = Satis(
        cariId: 'c2',
        tarih: gecenAy.subtract(const Duration(days: 10)), // Aralık dışı
        faturaNo: 'F2',
        araToplam: 200, kdvToplam: 36, iskonto: 0, genelToplam: 236,
        odemeTuru: 'Nakit', odenenTutar: 236, kasiyerId: '1',
      );

      await fakeFirestore.collection('satislar').add(satis1.toMap());
      await fakeFirestore.collection('satislar').add(satis2.toMap());

      final sonuclar = await raporService.getSatislar(gecenAy, bugun.add(const Duration(days: 1)));

      expect(sonuclar.length, 1);
      expect(sonuclar.first.faturaNo, 'F1');
    });

    test('getTahsilatOdemeHareketleri() sadece tahsilat/ödeme içerenleri getirmeli', () async {
      final hareket1 = CariHareket(
        cariId: 'c1',
        islemTuru: 'Tahsilat',
        evrakNo: 'T1',
        tutar: 100,
        tarih: DateTime.now(),
        islemTipi: 'ODEME_AL',
        aciklama: 'Tahsilat yapıldı',
      );
      
      final hareket2 = CariHareket(
        cariId: 'c1',
        islemTuru: 'Satış',
        evrakNo: 'S1',
        tutar: 500,
        tarih: DateTime.now(),
        islemTipi: 'SATIS',
        aciklama: 'Mal satışı',
      );

      await fakeFirestore.collection('cari_hareketler').add(hareket1.toMap());
      await fakeFirestore.collection('cari_hareketler').add(hareket2.toMap());

      final sonuclar = await raporService.getTahsilatOdemeHareketleri(
        DateTime.now().subtract(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 1)),
      );

      expect(sonuclar.length, 1);
      expect(sonuclar.first.islemTipi, 'ODEME_AL');
      expect(sonuclar.first.evrakNo, 'T1');
    });
  });
}
