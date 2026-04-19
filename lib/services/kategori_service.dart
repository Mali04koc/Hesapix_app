import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/kategori_model.dart';

class KategoriService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Yeni Kategori Ekleme
  Future<void> addKategori(Kategori kategori) async {
    QuerySnapshot query = await _db
        .collection('kategoriler')
        .orderBy('kategori_id', descending: true)
        .limit(1)
        .get();

    int nextId = 1;
    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data() as Map<String, dynamic>;
      final currentMax = data['kategori_id'] as int? ?? 0;
      nextId = currentMax + 1;
    }

    final newKategori = Kategori(
      id: kategori.id,
      kategoriId: nextId,
      isim: kategori.isim,
      adet: kategori.adet,
    );

    await _db.collection('kategoriler').add(newKategori.toMap());
  }

  // Tüm Kategorileri Getirme
  Stream<List<Kategori>> getKategoriler() {
    return _db.collection('kategoriler').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Kategori.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Kategori Güncelleme
  Future<void> updateKategori(Kategori kategori) async {
    if (kategori.id != null) {
      await _db
          .collection('kategoriler')
          .doc(kategori.id)
          .update(kategori.toMap());
    }
  }

  // Kategori Silme
  Future<void> deleteKategori(String id) async {
    await _db.collection('kategoriler').doc(id).delete();
  }
}
