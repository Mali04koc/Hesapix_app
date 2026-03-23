import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/tedarikci_model.dart';

class TedarikciService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Yeni Tedarikçi Ekleme
  Future<void> addTedarikci(Tedarikci tedarikci) async {
    await _db.collection('tedarikciler').add(tedarikci.toMap());
  }

  // Tüm Tedarikçileri Getirme
  Stream<List<Tedarikci>> getTedarikciler() {
    return _db.collection('tedarikciler').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Tedarikci.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Tedarikçi Güncelleme
  Future<void> updateTedarikci(Tedarikci tedarikci) async {
    if (tedarikci.id != null) {
      await _db
          .collection('tedarikciler')
          .doc(tedarikci.id)
          .update(tedarikci.toMap());
    }
  }

  // Tedarikçi Silme
  Future<void> deleteTedarikci(String id) async {
    await _db.collection('tedarikciler').doc(id).delete();
  }

  // Tedarikçi Borç (Bizim ona olan borcumuz) Güncelleme
  Future<void> addBorcToTedarikciByTedarikciId(int tedarikciId, double eklenecekBorc) async {
    if (eklenecekBorc <= 0) return;

    // tedarikci_id'ye göre tedarikçiyi bulup borcu artırıyoruz
    QuerySnapshot query = await _db
        .collection('tedarikciler')
        .where('tedarikci_id', isEqualTo: tedarikciId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      DocumentSnapshot doc = query.docs.first;
      double mevcutBorc = (doc.get('borc') ?? 0).toDouble();
      double yeniBorc = mevcutBorc + eklenecekBorc;

      await _db.collection('tedarikciler').doc(doc.id).update({
        'borc': yeniBorc,
      });
    }
  }
}
