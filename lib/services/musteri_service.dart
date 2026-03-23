import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/musteri_model.dart';

class MusteriService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Yeni Müşteri Ekleme
  Future<void> addMusteri(Musteri musteri) async {
    await _db.collection('musteriler').add(musteri.toMap());
  }

  // Tüm Müşterileri Getirme
  Stream<List<Musteri>> getMusteriler() {
    return _db.collection('musteriler').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Musteri.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Müşteri Güncelleme
  Future<void> updateMusteri(Musteri musteri) async {
    if (musteri.id != null) {
      await _db
          .collection('musteriler')
          .doc(musteri.id)
          .update(musteri.toMap());
    }
  }

  // Müşteri Silme
  Future<void> deleteMusteri(String id) async {
    await _db.collection('musteriler').doc(id).delete();
  }

  // Müşteri Borç Güncelleme (Siparişe göre)
  // Eklenen borç, müşterinin mevcut borcuna eklenecektir.
  Future<void> addBorcToMusteriByMusteriId(int musteriId, double eklenecekBorc) async {
    if (eklenecekBorc <= 0) return;

    // musteriId'ye göre müşteriyi bulup borcunu güncelliyoruz.
    QuerySnapshot query = await _db
        .collection('musteriler')
        .where('musteri_id', isEqualTo: musteriId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      DocumentSnapshot doc = query.docs.first;
      double mevcutBorc = (doc.get('musteri_borc') ?? 0).toDouble();
      double yeniBorc = mevcutBorc + eklenecekBorc;

      await _db.collection('musteriler').doc(doc.id).update({
        'musteri_borc': yeniBorc,
      });
    }
  }
}
