import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/kasiyer_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- KASİYER İŞLEMLERİ ---

  // Yeni Kasiyer Ekleme
  Future<void> addKasiyer(Kasiyer kasiyer) async {
    await _db.collection('kasiyerler').add(kasiyer.toMap());
  }

  // Tüm Kasiyerleri Getirme
  Stream<List<Kasiyer>> getKasiyerler() {
    return _db.collection('kasiyerler').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Kasiyer.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Kasiyer Güncelleme
  Future<void> updateKasiyer(Kasiyer kasiyer) async {
    if (kasiyer.id != null) {
      await _db
          .collection('kasiyerler')
          .doc(kasiyer.id)
          .update(kasiyer.toMap());
    }
  }

  // Kasiyer Silme
  Future<void> deleteKasiyer(String id) async {
    await _db.collection('kasiyerler').doc(id).delete();
  }
}
