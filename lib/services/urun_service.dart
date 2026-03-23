import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/urun_model.dart';

class UrunService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Yeni Ürün Ekleme
  Future<void> addUrun(Urun urun) async {
    await _db.collection('urunler').add(urun.toMap());
  }

  // Tüm Ürünleri Getirme
  Stream<List<Urun>> getUrunler() {
    return _db.collection('urunler').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Urun.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Ürün Güncelleme
  Future<void> updateUrun(Urun urun) async {
    if (urun.id != null) {
      await _db
          .collection('urunler')
          .doc(urun.id)
          .update(urun.toMap());
    }
  }

  // Ürün Silme
  Future<void> deleteUrun(String id) async {
    await _db.collection('urunler').doc(id).delete();
  }

  // Stok Güncelleme (Sipariş oluşturulduğunda çağrılacak)
  Future<void> decreaseStock(String urunId, int miktar) async {
    DocumentReference urunRef = _db.collection('urunler').doc(urunId);
    
    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(urunRef);

      if (!snapshot.exists) {
        throw Exception("Ürün bulunamadı!");
      }

      int mevcutStok = snapshot.get('stok') ?? 0;
      int yeniStok = mevcutStok - miktar;

      if (yeniStok < 0) {
        throw Exception("Yetersiz stok!");
      }

      transaction.update(urunRef, {'stok': yeniStok});
    });
  }
}
