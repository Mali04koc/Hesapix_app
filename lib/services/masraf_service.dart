import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/masraf_model.dart';

class MasrafService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Yeni Masraf Ekleme
  Future<void> addMasraf(Masraf masraf) async {
    await _db.collection('masraflar').add(masraf.toMap());
  }

  // Tüm Masrafları Getirme
  Stream<List<Masraf>> getMasraflar() {
    return _db.collection('masraflar').orderBy('tarih', descending: true).snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Masraf.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Masraf Güncelleme
  Future<void> updateMasraf(Masraf masraf) async {
    if (masraf.id != null) {
      await _db
          .collection('masraflar')
          .doc(masraf.id)
          .update(masraf.toMap());
    }
  }

  // Masraf Silme
  Future<void> deleteMasraf(String id) async {
    await _db.collection('masraflar').doc(id).delete();
  }

  // Tipe Göre Filtrelenmiş Masrafları Getirme
  Stream<List<Masraf>> getMasraflarByTip(String tip) {
    return _db
        .collection('masraflar')
        .where('tip', isEqualTo: tip)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Masraf.fromMap(doc.data(), doc.id))
            .toList());
  }
}
