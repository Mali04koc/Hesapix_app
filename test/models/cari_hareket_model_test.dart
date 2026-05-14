import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';

void main() {
  group('CariHareket Modeli Testleri', () {
    test('toMap() doğru bir Map döndürmeli', () {
      final tarih = DateTime(2023, 1, 1);
      final hareket = CariHareket(
        id: 'h1',
        cariId: 'c1',
        islemTipi: 'Tahsilat',
        tarih: tarih,
        tutar: 100.0,
        aciklama: 'Elden tahsilat',
      );

      final map = hareket.toMap();
      expect(map['cari_id'], 'c1');
      expect(map['islem_tipi'], 'Tahsilat');
      expect((map['tarih'] as Timestamp).toDate(), tarih);
      expect(map['tutar'], 100.0);
      expect(map['aciklama'], 'Elden tahsilat');
    });

    test('fromMap() doğru nesne oluşturmalı', () {
      final tarih = DateTime(2023, 1, 1);
      final map = {
        'cari_id': 'c1',
        'islem_tipi': 'Tahsilat',
        'tarih': Timestamp.fromDate(tarih),
        'tutar': 100.0,
        'aciklama': 'Elden tahsilat',
      };

      final hareket = CariHareket.fromMap(map, 'h1');
      expect(hareket.id, 'h1');
      expect(hareket.cariId, 'c1');
      expect(hareket.islemTipi, 'Tahsilat');
      expect(hareket.tarih, tarih);
      expect(hareket.tutar, 100.0);
      expect(hareket.aciklama, 'Elden tahsilat');
    });
  });
}
