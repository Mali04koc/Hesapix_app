import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hesapix_app/services/kategori_service.dart';
import 'package:hesapix_app/models/kategori_model.dart';

void main() {
  group('KategoriService Testleri', () {
    late FakeFirebaseFirestore fakeFirestore;
    late KategoriService kategoriService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      kategoriService = KategoriService(db: fakeFirestore);
    });

    test('addKategori() yeni kategori eklemeli ve kategori_id atamalı', () async {
      final kategori = Kategori(
        kategoriId: 0,
        isim: 'Mutfak',
      );

      await kategoriService.addKategori(kategori);

      final snapshot = await fakeFirestore.collection('kategoriler').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['kategori_id'], 1);
      expect(snapshot.docs.first.data()['isim'], 'Mutfak');
    });

    test('updateKategori() kategoriyi güncellemeli', () async {
      final docRef = await fakeFirestore.collection('kategoriler').add({
        'kategori_id': 1,
        'isim': 'Eski İsim',
      });

      final kategori = Kategori(
        id: docRef.id,
        kategoriId: 1,
        isim: 'Yeni İsim',
      );

      await kategoriService.updateKategori(kategori);

      final snapshot = await docRef.get();
      expect(snapshot.data()!['isim'], 'Yeni İsim');
    });

    test('deleteKategori() kategoriyi silmeli', () async {
      final docRef = await fakeFirestore.collection('kategoriler').add({
        'isim': 'Silinecek',
      });

      await kategoriService.deleteKategori(docRef.id);

      final snapshot = await fakeFirestore.collection('kategoriler').get();
      expect(snapshot.docs.isEmpty, true);
    });
  });
}
