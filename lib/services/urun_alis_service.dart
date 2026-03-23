import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/urun_alis_model.dart';
import 'package:hesapix_app/services/tedarikci_service.dart';
import 'package:hesapix_app/services/urun_service.dart';

class UrunAlisService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TedarikciService _tedarikciService = TedarikciService();
  final UrunService _urunService = UrunService();

  // Yeni Ürün Alışı (Siparişi) Ekleme
  Future<void> addUrunAlis(UrunAlis alis) async {
    double kalanBorc = alis.toplamTutar - alis.odenenTutar;

    // 1- Bizim tedarikçiye borcumuz kaldıysa bunu ekliyoruz
    if (kalanBorc > 0) {
      await _tedarikciService.addBorcToTedarikciByTedarikciId(
        alis.tedarikciId, 
        kalanBorc
      );
    }

    // 2- Satın aldığımız ürünün stoğunu artırıyoruz
    if (alis.adet > 0) {
      await _urunService.increaseStockByUrunId(alis.urunId, alis.adet);
    }

    // 3- Alış işlemini veritabanına ekle
    await _db.collection('urun_alislar').add(alis.toMap());
  }

  // Tüm Ürün Alışlarını Getirme
  Stream<List<UrunAlis>> getUrunAlislar() {
    return _db.collection('urun_alislar').orderBy('tarih', descending: true).snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => UrunAlis.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Belirli bir ürüne göre alış işlemleri
  Stream<List<UrunAlis>> getAlislarByUrunId(int urunId) {
    return _db
        .collection('urun_alislar')
        .where('urun_id', isEqualTo: urunId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UrunAlis.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Belirli bir tedarikçiden yapılan alışlar
  Stream<List<UrunAlis>> getAlislarByTedarikciId(int tedarikciId) {
    return _db
        .collection('urun_alislar')
        .where('tedarikci_id', isEqualTo: tedarikciId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UrunAlis.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Belirli bir ürün alışının borcunu ödeme
  // Ödenen miktar alış faturasına işlenir, bizim o tedarikçiye olan toplam borcumuz azalır.
  Future<void> payUrunAlisDebt(String alisDocId, double odenenMiktar) async {
    if (odenenMiktar <= 0) return;

    DocumentSnapshot alisDoc = await _db.collection('urun_alislar').doc(alisDocId).get();
    
    if (alisDoc.exists) {
      UrunAlis alis = UrunAlis.fromMap(alisDoc.data() as Map<String, dynamic>, alisDoc.id);

      double kalanAlisBorcu = alis.toplamTutar - alis.odenenTutar;
      if (kalanAlisBorcu <= 0) return; // Borç yok / Zaten ödenmiş

      double gerceklesecekOdeme = odenenMiktar;
      if (gerceklesecekOdeme > kalanAlisBorcu) {
        gerceklesecekOdeme = kalanAlisBorcu;
      }

      double yeniOdenenTutar = alis.odenenTutar + gerceklesecekOdeme;

      // Siparişi (Ürün Alış) güncelle
      await _db.collection('urun_alislar').doc(alis.id).update({
        'odenen_tutar': yeniOdenenTutar,
      });

      // Tedarikçiye olan toplam borcumuzu düş!!! (Eksi değer gönderiyoruz)
      await _tedarikciService.addBorcToTedarikciByTedarikciId(alis.tedarikciId, -gerceklesecekOdeme);
    }
  }
}
