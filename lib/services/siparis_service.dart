import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/siparis_model.dart';
import 'package:hesapix_app/services/musteri_service.dart';
import 'package:hesapix_app/services/urun_service.dart';

class SiparisService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final MusteriService _musteriService = MusteriService();
  final UrunService _urunService = UrunService();

  // Yeni Sipariş Ekleme, Stok Düşme ve Müşteri Borcunu Güncelleme
  Future<void> addSiparis(Siparis siparis) async {
    // 1- Kalan borcu müşteriye yansıtıyoruz (Eğer hesap açıksa!)
    double kalanBorc = siparis.toplamTutar - siparis.odenenTutar;
    bool odendiMi = (kalanBorc <= 0);

    if (!odendiMi && kalanBorc > 0) {
      await _musteriService.addBorcToMusteriByMusteriId(siparis.musteriId, kalanBorc);
    }

    // 2- Sepetteki ürünlerin stoğunu düşüyoruz
    // Satış array'i içerisinde { 'urun_doc_id': 'abc', 'adet': 2 } formatı beklendiği varsayılır.
    for (var urun in siparis.sepet) {
      if (urun.containsKey('urun_doc_id')) {
        String urunDocId = urun['urun_doc_id'];
        int adet = urun['adet'] ?? 1;
        await _urunService.decreaseStock(urunDocId, adet);
      }
    }

    // 3- Siparişi veritabanına ekle
    Map<String, dynamic> siparisMap = siparis.toMap();
    siparisMap['odendi'] = odendiMi; // Override odendi logic before pushing layer

    await _db.collection('siparisler').add(siparisMap);
  }

  // Tüm Siparişleri Getirme
  Stream<List<Siparis>> getSiparisler() {
    return _db.collection('siparisler').orderBy('tarih', descending: true).snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Siparis.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Sipariş Güncelleme
  Future<void> updateSiparis(Siparis siparis) async {
    if (siparis.id != null) {
      Map<String, dynamic> siparisMap = siparis.toMap();
      double kalanBorc = siparis.toplamTutar - siparis.odenenTutar;
      siparisMap['odendi'] = (kalanBorc <= 0);

      await _db
          .collection('siparisler')
          .doc(siparis.id)
          .update(siparisMap);
    }
  }

  // Sipariş Silme
  Future<void> deleteSiparis(String id) async {
    await _db.collection('siparisler').doc(id).delete();
  }

  // Spesifik müşterinin siparişleri
  Stream<List<Siparis>> getSiparislerByMusteriId(int musteriId) {
    return _db
        .collection('siparisler')
        .where('musteri_id', isEqualTo: musteriId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Siparis.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Spesifik kasiyerin siparişleri
  Stream<List<Siparis>> getSiparislerByKasiyerId(int kasiyerId) {
    return _db
        .collection('siparisler')
        .where('kasiyer_id', isEqualTo: kasiyerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Siparis.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Belirli bir siparişin borcunu ödeme
  // Ödenen miktar siparişe işlenir. Eğer odenenTutar >= toplamTutar olursa odendi = true olur.
  // Bu işlem sonucunda Müşterinin eksilen borcu musteri_borc üzerinden düşülür.
  Future<void> paySiparisDebt(String siparisDocId, double odenenMiktar) async {
    if (odenenMiktar <= 0) return;

    DocumentSnapshot siparisDoc = await _db.collection('siparisler').doc(siparisDocId).get();
    
    if (siparisDoc.exists) {
      Siparis siparis = Siparis.fromMap(siparisDoc.data() as Map<String, dynamic>, siparisDoc.id);

      // Sadece kalan borcu kadar ödeme yapılabilir. (Fazladan ödeme engellemesi)
      double kalanSiparisBorcu = siparis.toplamTutar - siparis.odenenTutar;
      if (kalanSiparisBorcu <= 0) return; // Zaten ödenmiş

      double gerceklesecekOdeme = odenenMiktar;
      if (gerceklesecekOdeme > kalanSiparisBorcu) {
        gerceklesecekOdeme = kalanSiparisBorcu;
      }

      double yeniOdenenTutar = siparis.odenenTutar + gerceklesecekOdeme;
      bool yeniOdendiDurumu = (siparis.toplamTutar - yeniOdenenTutar) <= 0;

      // Siparişi güncelle
      await _db.collection('siparisler').doc(siparis.id).update({
        'odenen_tutar': yeniOdenenTutar,
        'odendi': yeniOdendiDurumu,
      });

      // Müşterinin toplam borcundan bu miktarı düş!!! (Eksi bakiye vererek addBorc kullanabiliriz)
      await _musteriService.addBorcToMusteriByMusteriId(siparis.musteriId, -gerceklesecekOdeme);
    }
  }
}
