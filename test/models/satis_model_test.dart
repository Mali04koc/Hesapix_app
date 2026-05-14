import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/satis_model.dart';
import 'package:hesapix_app/models/satis_detay_model.dart';

void main() {
  group('Satis Modeli Testleri', () {
    test('toMap() doğru bir Map döndürmeli', () {
      final tarih = DateTime(2023, 1, 1);
      final satis = Satis(
        id: 'satis123',
        cariId: 'cari123',
        tarih: tarih,
        faturaNo: 'FAT-001',
        araToplam: 100.0,
        kdvToplam: 20.0,
        iskonto: 5.0,
        genelToplam: 115.0,
        odemeTuru: 'Nakit',
        odenenTutar: 115.0,
        kasiyerId: 'kasiyer1',
      );

      final map = satis.toMap();

      expect(map['cari_id'], 'cari123');
      expect(map['fatura_no'], 'FAT-001');
      expect(map['ara_toplam'], 100.0);
      expect(map['kdv_toplam'], 20.0);
      expect(map['iskonto'], 5.0);
      expect(map['genel_toplam'], 115.0);
      expect(map['odeme_turu'], 'Nakit');
      expect(map['odenen_tutar'], 115.0);
      expect(map['kasiyer_id'], 'kasiyer1');
      expect(map['tarih'], isA<Timestamp>());
      expect((map['tarih'] as Timestamp).toDate(), tarih);
    });

    test('fromMap() doğru bir Satis nesnesi oluşturmalı', () {
      final tarih = DateTime(2023, 1, 1);
      final map = {
        'cari_id': 'cari123',
        'tarih': Timestamp.fromDate(tarih),
        'fatura_no': 'FAT-001',
        'ara_toplam': 100.0,
        'kdv_toplam': 20.0,
        'iskonto': 5.0,
        'genel_toplam': 115.0,
        'odeme_turu': 'Nakit',
        'odenen_tutar': 115.0,
        'kasiyer_id': 'kasiyer1',
      };

      final satis = Satis.fromMap(map, 'satis123');

      expect(satis.id, 'satis123');
      expect(satis.cariId, 'cari123');
      expect(satis.tarih, tarih);
      expect(satis.faturaNo, 'FAT-001');
      expect(satis.araToplam, 100.0);
      expect(satis.kdvToplam, 20.0);
      expect(satis.iskonto, 5.0);
      expect(satis.genelToplam, 115.0);
      expect(satis.odemeTuru, 'Nakit');
      expect(satis.odenenTutar, 115.0);
      expect(satis.kasiyerId, 'kasiyer1');
    });
  });

  group('SatisDetay Modeli Testleri', () {
    test('toMap() doğru bir Map döndürmeli', () {
      final satisDetay = SatisDetay(
        id: 'detay1',
        satisId: 'satis1',
        urunId: 'urun1',
        urunAdi: 'Test Ürün',
        miktar: 2,
        birimFiyat: 50.0,
        kdvOrani: 20.0,
        araToplam: 100.0,
        kdvTutar: 20.0,
        toplam: 120.0,
      );

      final map = satisDetay.toMap();

      expect(map['satis_id'], 'satis1');
      expect(map['urun_id'], 'urun1');
      expect(map['urun_adi'], 'Test Ürün');
      expect(map['miktar'], 2);
      expect(map['birim_fiyat'], 50.0);
      expect(map['kdv_orani'], 20.0);
      expect(map['ara_toplam'], 100.0);
      expect(map['kdv_tutar'], 20.0);
      expect(map['toplam'], 120.0);
    });

    test('fromMap() doğru bir SatisDetay nesnesi oluşturmalı', () {
      final map = {
        'satis_id': 'satis1',
        'urun_id': 'urun1',
        'urun_adi': 'Test Ürün',
        'miktar': 2,
        'birim_fiyat': 50.0,
        'kdv_orani': 20.0,
        'ara_toplam': 100.0,
        'kdv_tutar': 20.0,
        'toplam': 120.0,
      };

      final satisDetay = SatisDetay.fromMap(map, 'detay1');

      expect(satisDetay.id, 'detay1');
      expect(satisDetay.satisId, 'satis1');
      expect(satisDetay.urunId, 'urun1');
      expect(satisDetay.urunAdi, 'Test Ürün');
      expect(satisDetay.miktar, 2);
      expect(satisDetay.birimFiyat, 50.0);
      expect(satisDetay.kdvOrani, 20.0);
      expect(satisDetay.araToplam, 100.0);
      expect(satisDetay.kdvTutar, 20.0);
      expect(satisDetay.toplam, 120.0);
    });
  });
}
