import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/alis_model.dart';
import 'package:hesapix_app/models/alis_detay_model.dart';

void main() {
  group('Alis Modeli Testleri', () {
    test('toMap() doğru bir Map döndürmeli', () {
      final tarih = DateTime(2023, 1, 1);
      final alis = Alis(
        id: 'alis123',
        cariId: 'cari123',
        tarih: tarih,
        faturaNo: 'ALIS-001',
        araToplam: 200.0,
        kdvToplam: 40.0,
        iskonto: 10.0,
        genelToplam: 230.0,
        odemeTuru: 'Kart',
        odenenTutar: 230.0,
        kasiyerId: 'kasiyer1',
      );

      final map = alis.toMap();

      expect(map['cari_id'], 'cari123');
      expect(map['fatura_no'], 'ALIS-001');
      expect(map['ara_toplam'], 200.0);
      expect(map['kdv_toplam'], 40.0);
      expect(map['iskonto'], 10.0);
      expect(map['genel_toplam'], 230.0);
      expect(map['odeme_turu'], 'Kart');
      expect(map['odenen_tutar'], 230.0);
      expect(map['kasiyer_id'], 'kasiyer1');
      expect(map['tarih'], isA<Timestamp>());
      expect((map['tarih'] as Timestamp).toDate(), tarih);
    });

    test('fromMap() doğru bir Alis nesnesi oluşturmalı', () {
      final tarih = DateTime(2023, 1, 1);
      final map = {
        'cari_id': 'cari123',
        'tarih': Timestamp.fromDate(tarih),
        'fatura_no': 'ALIS-001',
        'ara_toplam': 200.0,
        'kdv_toplam': 40.0,
        'iskonto': 10.0,
        'genel_toplam': 230.0,
        'odeme_turu': 'Kart',
        'odenen_tutar': 230.0,
        'kasiyer_id': 'kasiyer1',
      };

      final alis = Alis.fromMap(map, 'alis123');

      expect(alis.id, 'alis123');
      expect(alis.cariId, 'cari123');
      expect(alis.tarih, tarih);
      expect(alis.faturaNo, 'ALIS-001');
      expect(alis.araToplam, 200.0);
      expect(alis.kdvToplam, 40.0);
      expect(alis.iskonto, 10.0);
      expect(alis.genelToplam, 230.0);
      expect(alis.odemeTuru, 'Kart');
      expect(alis.odenenTutar, 230.0);
      expect(alis.kasiyerId, 'kasiyer1');
    });
  });

  group('AlisDetay Modeli Testleri', () {
    test('toMap() doğru bir Map döndürmeli', () {
      final alisDetay = AlisDetay(
        id: 'detay1',
        alisId: 'alis1',
        urunId: 'urun1',
        urunAdi: 'Test Ürün',
        miktar: 5,
        birimFiyat: 10.0,
        kdvOrani: 10.0,
        araToplam: 50.0,
        kdvTutar: 5.0,
        toplam: 55.0,
      );

      final map = alisDetay.toMap();

      expect(map['alis_id'], 'alis1');
      expect(map['urun_id'], 'urun1');
      expect(map['urun_adi'], 'Test Ürün');
      expect(map['miktar'], 5);
      expect(map['birim_fiyat'], 10.0);
      expect(map['kdv_orani'], 10.0);
      expect(map['ara_toplam'], 50.0);
      expect(map['kdv_tutar'], 5.0);
      expect(map['toplam'], 55.0);
    });

    test('fromMap() doğru bir AlisDetay nesnesi oluşturmalı', () {
      final map = {
        'alis_id': 'alis1',
        'urun_id': 'urun1',
        'urun_adi': 'Test Ürün',
        'miktar': 5,
        'birim_fiyat': 10.0,
        'kdv_orani': 10.0,
        'ara_toplam': 50.0,
        'kdv_tutar': 5.0,
        'toplam': 55.0,
      };

      final alisDetay = AlisDetay.fromMap(map, 'detay1');

      expect(alisDetay.id, 'detay1');
      expect(alisDetay.alisId, 'alis1');
      expect(alisDetay.urunId, 'urun1');
      expect(alisDetay.urunAdi, 'Test Ürün');
      expect(alisDetay.miktar, 5);
      expect(alisDetay.birimFiyat, 10.0);
      expect(alisDetay.kdvOrani, 10.0);
      expect(alisDetay.araToplam, 50.0);
      expect(alisDetay.kdvTutar, 5.0);
      expect(alisDetay.toplam, 55.0);
    });
  });
}
