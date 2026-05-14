import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/services/satis_provider.dart';
import 'package:hesapix_app/models/urun_model.dart';

void main() {
  group('SatisProvider Testleri', () {
    late SatisProvider provider;

    setUp(() {
      provider = SatisProvider();
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
      final urun = Urun(id: 'urun1', isim: 'Test Ürün', kategori: 'Genel', satisFiyat: 118.0, alisFiyat: 100.0, stokSayisi: 10);
      
      // KDV Dahil ve %18 varsayılan kdvOrani = 118 ise, kdv haric = 100, kdv = 18.
      provider.sepeteEkle(urun, eklenecekMiktar: 1);

      expect(provider.sepet.length, 1);
      expect(provider.sepet.first.urunId, 'urun1');
      expect(provider.sepet.first.miktar, 1);
      expect(provider.araToplam, closeTo(100.0, 0.1));
      expect(provider.kdvToplam, closeTo(18.0, 0.1));
      expect(provider.genelToplam, closeTo(118.0, 0.1));
    });

    test('Aynı ürün eklendiğinde miktarı artmalı', () {
      final urun = Urun(id: 'urun1', isim: 'Test Ürün', kategori: 'Genel', satisFiyat: 118.0, alisFiyat: 100.0, stokSayisi: 10);
      
      provider.sepeteEkle(urun, eklenecekMiktar: 1);
      provider.sepeteEkle(urun, eklenecekMiktar: 2);

      expect(provider.sepet.length, 1);
      expect(provider.sepet.first.miktar, 3);
      expect(provider.araToplam, closeTo(300.0, 0.1));
      expect(provider.kdvToplam, closeTo(54.0, 0.1));
      expect(provider.genelToplam, closeTo(354.0, 0.1));
    });

    test('Sepetten ürün çıkarılabilmeli', () {
      final urun = Urun(id: 'urun1', isim: 'Test', kategori: 'Genel', satisFiyat: 118.0, alisFiyat: 100.0, stokSayisi: 10);
      provider.sepeteEkle(urun);
      
      provider.sepettenCikar('urun1');
      
      expect(provider.sepet.isEmpty, true);
      expect(provider.araToplam, 0.0);
    });

    test('Miktar güncellenebilmeli', () {
      final urun = Urun(id: 'urun1', isim: 'Test', kategori: 'Genel', satisFiyat: 118.0, alisFiyat: 100.0, stokSayisi: 10);
      provider.sepeteEkle(urun, eklenecekMiktar: 1);
      
      provider.miktarGuncelle('urun1', 5);
      
      expect(provider.sepet.first.miktar, 5);
      expect(provider.genelToplam, closeTo(590.0, 0.1));
    });

    test('Miktar 0 veya altına düştüğünde ürün sepetten çıkarılmalı', () {
      final urun = Urun(id: 'urun1', isim: 'Test', kategori: 'Genel', satisFiyat: 118.0, alisFiyat: 100.0, stokSayisi: 10);
      provider.sepeteEkle(urun, eklenecekMiktar: 2);
      
      provider.miktarGuncelle('urun1', 0);
      
      expect(provider.sepet.isEmpty, true);
    });

    test('KDV Dahil/Hariç değişimi toplamları etkilemeli', () {
      final urun = Urun(id: 'urun1', isim: 'Test', kategori: 'Genel', satisFiyat: 100.0, alisFiyat: 80.0, stokSayisi: 10);
      provider.sepeteEkle(urun, eklenecekMiktar: 1);
      
      // Varsayılan KDV Dahil = true (satisFiyat=100 -> kdv_haric ~84.7, kdv ~15.3, genel = 100)
      expect(provider.genelToplam, closeTo(100.0, 0.1));

      // KDV Hariç yap (satisFiyat=100 -> kdv_haric=100, kdv=18, genel = 118)
      provider.setKdvDahil(false);
      
      expect(provider.araToplam, closeTo(100.0, 0.1));
      expect(provider.kdvToplam, closeTo(18.0, 0.1));
      expect(provider.genelToplam, closeTo(118.0, 0.1));
    });

    test('İskonto genel toplamı düşürmeli', () {
      final urun = Urun(id: 'urun1', isim: 'Test', kategori: 'Genel', satisFiyat: 118.0, alisFiyat: 100.0, stokSayisi: 10);
      provider.sepeteEkle(urun, eklenecekMiktar: 1);
      
      provider.setIskonto(18.0);
      
      expect(provider.genelToplam, closeTo(100.0, 0.1));
    });
    
    test('Sepet temizlenebilmeli', () {
      final urun = Urun(id: 'urun1', isim: 'Test', kategori: 'Genel', satisFiyat: 118.0, alisFiyat: 100.0, stokSayisi: 10);
      provider.sepeteEkle(urun);
      provider.setCariId('cari123');
      provider.setOdemeTuru('Kart');
      provider.setIskonto(10.0);
      
      provider.sepetiTemizle();
      
      expect(provider.sepet.isEmpty, true);
      expect(provider.seciliCariId, '');
      expect(provider.odemeTuru, 'Nakit');
      expect(provider.iskonto, 0.0);
      expect(provider.genelToplam, 0.0);
    });
  });
}
