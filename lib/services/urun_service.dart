import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/urun_model.dart';

class UrunService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Yeni Ürün Ekleme
  Future<void> addUrun(Urun urun) async {
    QuerySnapshot query = await _db
        .collection('urunler')
        .orderBy('urun_id', descending: true)
        .limit(1)
        .get();

    int nextId = 1;
    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data() as Map<String, dynamic>;
      final currentMax = data['urun_id'] as int? ?? 0;
      nextId = currentMax + 1;
    }

    final newUrun = Urun(
      id: urun.id,
      urunId: nextId,
      isim: urun.isim,
      alisFiyat: urun.alisFiyat,
      satisFiyat: urun.satisFiyat,
      stok: urun.stok,
      barkod: urun.barkod,
      gorsel: urun.gorsel,
      kategoriId: urun.kategoriId,
    );

    await _db.collection('urunler').add(newUrun.toMap());
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

  // Stok Artırma (Ürün alış faturası işlendiğinde çağrılacak)
  Future<void> increaseStockByUrunId(int urunId, int miktar) async {
    QuerySnapshot query = await _db
        .collection('urunler')
        .where('urun_id', isEqualTo: urunId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      DocumentSnapshot doc = query.docs.first;
      int mevcutStok = doc.get('stok') ?? 0;
      int yeniStok = mevcutStok + miktar;

      await _db.collection('urunler').doc(doc.id).update({'stok': yeniStok});
    }
  }
}
