import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hesapix_app/services/rapor_service.dart';
import 'package:hesapix_app/models/satis_model.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';
import 'package:hesapix_app/models/alis_model.dart';
import 'package:hesapix_app/models/satis_detay_model.dart';
import '../helpers/test_fixtures.dart';

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

    test('getAlislar() tarih aralığına göre filtrelemeli', () async {
      final bugun = DateTime.now();
      final baslangic = bugun.subtract(const Duration(days: 7));

      await fakeFirestore.collection('alislar').add(
        Alis(
          cariId: 'c1',
          tarih: bugun,
          faturaNo: 'A1',
          araToplam: 100,
          kdvToplam: 18,
          iskonto: 0,
          genelToplam: 118,
          odemeTuru: 'Nakit',
          odenenTutar: 118,
          kasiyerId: '1',
        ).toMap(),
      );

      final sonuclar = await raporService.getAlislar(
        baslangic,
        bugun.add(const Duration(days: 1)),
      );
      expect(sonuclar.length, 1);
      expect(sonuclar.first.faturaNo, 'A1');
    });

    test('getCariler() ve getTumUrunler() tüm kayıtları döndürmeli', () async {
      await fakeFirestore.collection('cariler').add(sampleCari().toMap());
      await fakeFirestore.collection('urunler').add(sampleUrun().toMap());

      final cariler = await raporService.getCariler();
      final urunler = await raporService.getTumUrunler();

      expect(cariler.length, 1);
      expect(urunler.length, 1);
      expect(urunler.first.isim, 'Test Ürün');
    });

    test('getSatisDetaylari() satışlara bağlı detayları getirmeli', () async {
      final bugun = DateTime.now();
      final satisRef = await fakeFirestore.collection('satislar').add(
        Satis(
          cariId: 'c1',
          tarih: bugun,
          faturaNo: 'F1',
          araToplam: 100,
          kdvToplam: 18,
          iskonto: 0,
          genelToplam: 118,
          odemeTuru: 'Nakit',
          odenenTutar: 118,
          kasiyerId: '1',
        ).toMap(),
      );

      await fakeFirestore.collection('satis_detaylari').add(
        SatisDetay(
          satisId: satisRef.id,
          urunId: 'u1',
          urunAdi: 'Ürün',
          miktar: 1,
          birimFiyat: 100,
          kdvOrani: 18,
          araToplam: 100,
          kdvTutar: 18,
          toplam: 118,
        ).toMap(),
      );

      final detaylar = await raporService.getSatisDetaylari(
        bugun.subtract(const Duration(days: 1)),
        bugun.add(const Duration(days: 1)),
      );

      expect(detaylar.length, 1);
      expect(detaylar.first.urunAdi, 'Ürün');
    });

    test('getCariHareketler() belirli cari için filtrelemeli', () async {
      final tarih = DateTime.now();
      await fakeFirestore.collection('cari_hareketler').add(
        CariHareket(
          cariId: 'c1',
          islemTuru: 'Tahsilat',
          evrakNo: 'T1',
          tutar: 50,
          tarih: tarih,
          islemTipi: 'ODEME_AL',
          aciklama: 'Tahsilat',
        ).toMap(),
      );
      await fakeFirestore.collection('cari_hareketler').add(
        CariHareket(
          cariId: 'c2',
          islemTuru: 'Tahsilat',
          evrakNo: 'T2',
          tutar: 99,
          tarih: tarih,
          islemTipi: 'ODEME_AL',
          aciklama: 'Başka cari',
        ).toMap(),
      );

      final sonuclar = await raporService.getCariHareketler(
        'c1',
        tarih.subtract(const Duration(days: 1)),
        tarih.add(const Duration(days: 1)),
      );

      expect(sonuclar.length, 1);
      expect(sonuclar.first.cariId, 'c1');
    });

    test('getAlisDetaylari() alış detaylarını getirmeli', () async {
      final bugun = DateTime.now();
      final alisRef = await fakeFirestore.collection('alislar').add(
        Alis(
          cariId: 'c1',
          tarih: bugun,
          faturaNo: 'A1',
          araToplam: 100,
          kdvToplam: 18,
          iskonto: 0,
          genelToplam: 118,
          odemeTuru: 'Nakit',
          odenenTutar: 118,
          kasiyerId: '1',
        ).toMap(),
      );

      await fakeFirestore.collection('alis_detaylari').add({
        'alis_id': alisRef.id,
        'urun_id': 'u1',
        'urun_adi': 'Mal',
        'miktar': 1,
        'birim_fiyat': 100.0,
        'kdv_orani': 18.0,
        'ara_toplam': 100.0,
        'kdv_tutar': 18.0,
        'toplam': 118.0,
      });

      final detaylar = await raporService.getAlisDetaylari(
        bugun.subtract(const Duration(days: 1)),
        bugun.add(const Duration(days: 1)),
      );

      expect(detaylar.length, 1);
      expect(detaylar.first.urunAdi, 'Mal');
    });

    test('getTumCariHareketler() tarih aralığındaki hareketleri getirmeli', () async {
      final tarih = DateTime.now();
      await fakeFirestore.collection('cari_hareketler').add(
        CariHareket(
          cariId: 'c1',
          islemTuru: 'Tahsilat',
          evrakNo: 'T1',
          tutar: 10,
          tarih: tarih,
          islemTipi: 'ODEME_AL',
          aciklama: 'A',
        ).toMap(),
      );

      final list = await raporService.getTumCariHareketler(
        tarih.subtract(const Duration(days: 1)),
        tarih.add(const Duration(days: 1)),
      );
      expect(list.length, 1);
    });

    test('getKasiyerler() kullanıcı listesi döndürmeli', () async {
      await seedKullanici(
        fakeFirestore,
        id: 'k1',
        email: 'kasiyer@test.com',
        rol: 'Kasiyer',
      );

      final users = await raporService.getKasiyerler();
      expect(users.length, 1);
      expect(users.first.email, 'kasiyer@test.com');
    });

    test('getSatisDetaylari() satış yoksa boş liste döner', () async {
      final bugun = DateTime.now();
      final detaylar = await raporService.getSatisDetaylari(
        bugun.subtract(const Duration(days: 30)),
        bugun,
      );
      expect(detaylar, isEmpty);
    });
  });
}
