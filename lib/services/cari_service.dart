import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';

class CariService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Yeni Cari Ekleme
  Future<void> addCari(Cari cari) async {
    await _db.collection('cariler').add(cari.toMap());
  }

  // Cari Arama
  Future<List<Cari>> cariAra(String arama) async {
    final query = arama.toLowerCase();
    final snapshot = await _db.collection('cariler').get();
    return snapshot.docs
        .map((doc) => Cari.fromMap(doc.data(), doc.id))
        .where((c) => c.firmaAdi.toLowerCase().contains(query) || c.cariKodu.toLowerCase().contains(query))
        .toList();
  }

  // Tüm Carileri Getirme
  Stream<List<Cari>> getCariler() {
    return _db.collection('cariler').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Cari.fromMap(doc.data(), doc.id)).toList());
  }

  // Cari Güncelleme
  Future<void> updateCari(Cari cari) async {
    if (cari.id != null) {
      await _db.collection('cariler').doc(cari.id).update(cari.toMap());
    }
  }

  // Cari Silme
  Future<void> deleteCari(String id) async {
    await _db.collection('cariler').doc(id).delete();
  }

  // --- Cari Hareketleri İşlemleri ---

  // Yeni Cari Hareket Ekleme
  Future<void> addHareket(CariHareket hareket) async {
    await _db.collection('cari_hareketler').add(hareket.toMap());

    double bakiyeEtkisi = 0;
    switch (hareket.islemTipi) {
      case "SATIS":
        bakiyeEtkisi = hareket.tutar; // bize borçlandı
        break;
      case "ALIS":
        bakiyeEtkisi = -hareket.tutar; // biz borçlandık
        break;
      case "ODEME_AL":
        bakiyeEtkisi = -hareket.tutar; // borç azalır
        break;
      case "ODEME_YAP":
        bakiyeEtkisi = hareket.tutar; // bizim borç azalır
        break;
    }

    DocumentSnapshot cariDoc = await _db.collection('cariler').doc(hareket.cariId).get();
    if (cariDoc.exists) {
      double mevcutBakiye = (cariDoc.data() as Map<String, dynamic>)['bakiye']?.toDouble() ?? 0.0;
      double yeniBakiye = mevcutBakiye + bakiyeEtkisi;
      await _db.collection('cariler').doc(hareket.cariId).update({
        'bakiye': yeniBakiye,
        'son_islem_tarihi': Timestamp.now()
      });
    }
  }

  // Belirli bir Cari'nin hareketlerini getirme
  Stream<List<CariHareket>> getHareketler(String cariId) {
    return _db
        .collection('cari_hareketler')
        .where('cari_id', isEqualTo: cariId)
        .orderBy('tarih', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CariHareket.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Tüm Cari Hareketlerini getirme (Genel Geçmiş)
  Stream<List<CariHareket>> getAllHareketler() {
    return _db
        .collection('cari_hareketler')
        .orderBy('tarih', descending: true)
        .limit(50) // Son 50 işlemi göster
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CariHareket.fromMap(doc.data(), doc.id))
            .toList());
  }
}
