import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/models/satis_detay_model.dart';

void main() {
  group('SatisDetay Modeli Testleri', () {
    test('toMap() doğru bir Map döndürmeli', () {
      final detay = SatisDetay(
        id: '1',
        satisId: 'satis1',
        urunId: 'urun1',
        urunAdi: 'Test Ürün',
        miktar: 5,
        birimFiyat: 100.0,
        kdvOrani: 18.0,
        araToplam: 500.0,
        kdvTutar: 90.0,
        toplam: 590.0,
      );

      final map = detay.toMap();
      expect(map['satis_id'], 'satis1');
      expect(map['urun_id'], 'urun1');
      expect(map['urun_adi'], 'Test Ürün');
      expect(map['miktar'], 5);
      expect(map['birim_fiyat'], 100.0);
      expect(map['kdv_orani'], 18.0);
      expect(map['ara_toplam'], 500.0);
      expect(map['kdv_tutar'], 90.0);
      expect(map['toplam'], 590.0);
    });

    test('fromMap() doğru nesne oluşturmalı', () {
      final map = {
        'satis_id': 'satis1',
        'urun_id': 'urun1',
        'urun_adi': 'Test Ürün',
        'miktar': 5,
        'birim_fiyat': 100.0,
        'kdv_orani': 18.0,
        'ara_toplam': 500.0,
        'kdv_tutar': 90.0,
        'toplam': 590.0,
      };

      final detay = SatisDetay.fromMap(map, '1');
      expect(detay.id, '1');
      expect(detay.satisId, 'satis1');
      expect(detay.urunId, 'urun1');
      expect(detay.urunAdi, 'Test Ürün');
      expect(detay.miktar, 5);
      expect(detay.birimFiyat, 100.0);
      expect(detay.kdvOrani, 18.0);
      expect(detay.araToplam, 500.0);
      expect(detay.kdvTutar, 90.0);
      expect(detay.toplam, 590.0);
    });
  });
}
