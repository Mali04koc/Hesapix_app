import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/models/kategori_model.dart';

void main() {
  group('Kategori Modeli Testleri', () {
    test('toMap() doğru bir Map döndürmeli', () {
      final kategori = Kategori(
        id: 'kat1',
        kategoriId: 1,
        isim: 'Elektronik',
        cesit: 5,
        adet: 100,
      );

      final map = kategori.toMap();

      expect(map['kategori_id'], 1);
      expect(map['isim'], 'Elektronik');
      expect(map['cesit'], 5);
      expect(map['adet'], 100);
    });

    test('fromMap() doğru bir Kategori nesnesi oluşturmalı', () {
      final map = {
        'kategori_id': 1,
        'isim': 'Elektronik',
        'cesit': 5,
        'adet': 100,
      };

      final kategori = Kategori.fromMap(map, 'kat1');

      expect(kategori.id, 'kat1');
      expect(kategori.kategoriId, 1);
      expect(kategori.isim, 'Elektronik');
      expect(kategori.cesit, 5);
      expect(kategori.adet, 100);
    });

    test('fromMap() eski versiyon verilerde (cesit yok, sadece adet var) doğru çalışmalı', () {
      final map = {
        'kategori_id': 1,
        'isim': 'Elektronik',
        'adet': 100,
        // 'cesit' bilerek eklenmedi
      };

      final kategori = Kategori.fromMap(map, 'kat1');

      expect(kategori.cesit, 100); // Fallback to 'adet'
      expect(kategori.adet, 100);
    });
  });
}
