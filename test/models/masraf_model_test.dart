import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/models/masraf_model.dart';

void main() {
  group('Masraf Modeli Testleri', () {
    test('toMap() doğru bir Map döndürmeli', () {
      final tarih = DateTime(2023, 1, 1);
      final masraf = Masraf(
        id: 'm1',
        masrafId: 1,
        tip: 'elektrik',
        tutar: 500.0,
        tarih: tarih,
        aciklama: 'Ocak ayı faturası',
      );

      final map = masraf.toMap();

      expect(map['masraf_id'], 1);
      expect(map['tip'], 'elektrik');
      expect(map['tutar'], 500.0);
      expect(map['tarih'], tarih.toIso8601String());
      expect(map['aciklama'], 'Ocak ayı faturası');
    });

    test('fromMap() doğru bir Masraf nesnesi oluşturmalı', () {
      final tarihStr = '2023-01-01T00:00:00.000';
      final map = {
        'masraf_id': 1,
        'tip': 'su',
        'tutar': 150.0,
        'tarih': tarihStr,
        'aciklama': 'Su faturası',
      };

      final masraf = Masraf.fromMap(map, 'm1');

      expect(masraf.id, 'm1');
      expect(masraf.masrafId, 1);
      expect(masraf.tip, 'su');
      expect(masraf.tutar, 150.0);
      expect(masraf.aciklama, 'Su faturası');
      expect(masraf.tarih, DateTime.parse(tarihStr));
    });
  });
}
