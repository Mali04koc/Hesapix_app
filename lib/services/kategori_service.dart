import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/kategori_model.dart';

class KategoriService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Yeni Kategori Ekleme
  Future<void> addKategori(Kategori kategori) async {
    await _db.collection('kategoriler').add(kategori.toMap());
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
