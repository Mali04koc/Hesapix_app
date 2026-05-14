import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/models/urun_model.dart';

void main() {
  group('Urun Modeli Testleri', () {
    test('toMap() doğru bir Map döndürmeli', () {
      final urun = Urun(
        id: 'doc123',
        urunId: 1,
        isim: 'Test Ürün',
        alisFiyat: 100.0,
        satisFiyat: 150.0,
        stok: 50,
        barkod: '1234567890123',
        gorsel: 'https://example.com/image.png',
        kategoriId: 'kat1',
        urunKodu: 'URUN-001',
        tedarikciKodu: 'TED-001',
      );

      final map = urun.toMap();

      expect(map['urun_id'], 1);
      expect(map['isim'], 'Test Ürün');
      expect(map['alis_fiyat'], 100.0);
      expect(map['satis_fiyat'], 150.0);
      expect(map['stok'], 50);
      expect(map['barkod'], '1234567890123');
      expect(map['gorsel'], 'https://example.com/image.png');
      expect(map['kategori_id'], 'kat1');
      expect(map['urun_kodu'], 'URUN-001');
      expect(map['tedarikci_kodu'], 'TED-001');
    });

    test('fromMap() doğru bir Urun nesnesi oluşturmalı', () {
      final map = {
        'urun_id': 1,
        'isim': 'Test Ürün',
        'alis_fiyat': 100.0,
        'satis_fiyat': 150.0,
        'stok': 50,
        'barkod': '1234567890123',
        'gorsel': 'https://example.com/image.png',
        'kategori_id': 'kat1',
        'urun_kodu': 'URUN-001',
        'tedarikci_kodu': 'TED-001',
      };

      final urun = Urun.fromMap(map, 'doc123');

      expect(urun.id, 'doc123');
      expect(urun.urunId, 1);
      expect(urun.isim, 'Test Ürün');
      expect(urun.alisFiyat, 100.0);
      expect(urun.satisFiyat, 150.0);
      expect(urun.stok, 50);
      expect(urun.barkod, '1234567890123');
      expect(urun.gorsel, 'https://example.com/image.png');
      expect(urun.kategoriId, 'kat1');
      expect(urun.urunKodu, 'URUN-001');
      expect(urun.tedarikciKodu, 'TED-001');
    });

    test('fromMap() eksik verilerle default değerleri atamalı', () {
      final map = <String, dynamic>{};

      final urun = Urun.fromMap(map, 'doc123');

      expect(urun.id, 'doc123');
      expect(urun.urunId, 0);
      expect(urun.isim, '');
      expect(urun.alisFiyat, 0.0);
      expect(urun.satisFiyat, 0.0);
      expect(urun.stok, 0);
      expect(urun.barkod, '');
    });
  });
}
