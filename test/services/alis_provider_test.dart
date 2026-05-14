import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/services/alis_provider.dart';
import 'package:hesapix_app/models/urun_model.dart';

void main() {
  group('AlisProvider Testleri', () {
    late AlisProvider provider;

    setUp(() {
      provider = AlisProvider();
    });

    test('Başlangıç değerleri doğru olmalı', () {
      expect(provider.sepet.isEmpty, true);
      expect(provider.seciliCariId, '');
      expect(provider.odemeTuru, 'Nakit');
      expect(provider.iskonto, 0.0);
      expect(provider.kdvDahil, true);
      expect(provider.araToplam, 0.0);
      expect(provider.kdvToplam, 0.0);
      expect(provider.genelToplam, 0.0);
    });

    test('Sepete ürün eklenebilmeli', () {
      final urun = Urun(id: 'urun1', urunId: 1, isim: 'Test Ürün', kategoriId: 'k1', alisFiyat: 100.0, satisFiyat: 150.0, stok: 10, barkod: '', gorsel: '', urunKodu: '', tedarikciKodu: '');
      
      // Varsayılan KDV Dahil = true ve oran %18 (100 üzerinden kdv hariç ~84.74)
      provider.sepeteEkle(urun, eklenecekMiktar: 1);

      expect(provider.sepet.length, 1);
      expect(provider.sepet.first.urunId, 'urun1');
      expect(provider.sepet.first.miktar, 1);
      expect(provider.genelToplam, closeTo(100.0, 0.1));
    });

    test('Fiyat güncellenebilmeli', () {
      final urun = Urun(id: 'urun1', urunId: 1, isim: 'Test', kategoriId: 'k1', alisFiyat: 100.0, satisFiyat: 150.0, stok: 10, barkod: '', gorsel: '', urunKodu: '', tedarikciKodu: '');
      provider.sepeteEkle(urun, eklenecekMiktar: 1);
      
      provider.fiyatGuncelle('urun1', 200.0);
      
      expect(provider.genelToplam, closeTo(200.0, 0.1));
      expect(provider.sepet.first.birimFiyat, 200.0);
    });

    test('Aynı ürün eklendiğinde miktarı artmalı', () {
      final urun = Urun(id: 'urun1', urunId: 1, isim: 'Test', kategoriId: 'k1', alisFiyat: 100.0, satisFiyat: 150.0, stok: 10, barkod: '', gorsel: '', urunKodu: '', tedarikciKodu: '');
      
      provider.sepeteEkle(urun, eklenecekMiktar: 1);
      provider.sepeteEkle(urun, eklenecekMiktar: 2);

      expect(provider.sepet.length, 1);
      expect(provider.sepet.first.miktar, 3);
      expect(provider.genelToplam, closeTo(300.0, 0.1));
    });

    test('Sepetten ürün çıkarılabilmeli', () {
      final urun = Urun(id: 'urun1', urunId: 1, isim: 'Test', kategoriId: 'k1', alisFiyat: 100.0, satisFiyat: 150.0, stok: 10, barkod: '', gorsel: '', urunKodu: '', tedarikciKodu: '');
      provider.sepeteEkle(urun);
      
      provider.sepettenCikar('urun1');
      
      expect(provider.sepet.isEmpty, true);
    });

    test('Miktar güncellenebilmeli', () {
      final urun = Urun(id: 'urun1', urunId: 1, isim: 'Test', kategoriId: 'k1', alisFiyat: 100.0, satisFiyat: 150.0, stok: 10, barkod: '', gorsel: '', urunKodu: '', tedarikciKodu: '');
      provider.sepeteEkle(urun, eklenecekMiktar: 1);
      
      provider.miktarGuncelle('urun1', 5);
      
      expect(provider.sepet.first.miktar, 5);
      expect(provider.genelToplam, closeTo(500.0, 0.1));
    });

    test('KDV Dahil/Hariç değişimi çalışmalı', () {
      final urun = Urun(id: 'urun1', urunId: 1, isim: 'Test', kategoriId: 'k1', alisFiyat: 100.0, satisFiyat: 150.0, stok: 10, barkod: '', gorsel: '', urunKodu: '', tedarikciKodu: '');
      provider.sepeteEkle(urun, eklenecekMiktar: 1);
      
      // KDV Dahil = true (genel=100)
      expect(provider.genelToplam, closeTo(100.0, 0.1));

      // KDV Hariç yap (ara=100, kdv=18, genel=118)
      provider.setKdvDahil(false);
      
      expect(provider.araToplam, closeTo(100.0, 0.1));
      expect(provider.kdvToplam, closeTo(18.0, 0.1));
      expect(provider.genelToplam, closeTo(118.0, 0.1));
    });
  });
}
