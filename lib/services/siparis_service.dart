import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/siparis_model.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';
import 'package:hesapix_app/services/cari_service.dart';
import 'package:hesapix_app/services/urun_service.dart';

class SiparisService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CariService _cariService = CariService();
  final UrunService _urunService = UrunService();

  // Yeni Sipariş Ekleme, Stok Düşme ve Cari Borcunu Güncelleme
  Future<void> addSiparis(Siparis siparis) async {
    // 1- Önce stok kontrolü yapalım
    // Sepetteki ürünlerin stoklarının yeterli olup olmadığını kontrol ediyoruz
    for (var urun in siparis.sepet) {
      if (urun.containsKey('urun_doc_id')) {
        String urunDocId = urun['urun_doc_id'];
        int istenenAdet = urun['adet'] ?? 1;
        String urunIsmi = urun['urun_ismi'] ?? 'Bilinmeyen Ürün';

        DocumentSnapshot urunSnap = await _db.collection('urunler').doc(urunDocId).get();
        if (urunSnap.exists) {
          int mevcutStok = urunSnap.get('stok') ?? 0;
          if (mevcutStok < istenenAdet) {
            throw Exception('"$urunIsmi" ürününden stokta yalnızca $mevcutStok adet var!');
          }
        } else {
          throw Exception('"$urunIsmi" adlı ürün veritabanında bulunamadı.');
        }
      }
    }

    // 2- Kalan borcu Cari'ye hareket olarak ekleyelim
    double kalanBorc = siparis.toplamTutar - siparis.odenenTutar;
    bool odendiMi = (kalanBorc <= 0);

    // Siparişin toplam tutarını CariHareket "SATIS" olarak ekleyelim ki ekstrede görünsün
    await _cariService.addHareket(CariHareket(
      cariId: siparis.cariId,
      tarih: siparis.tarih,
      islemTipi: 'SATIS',
      tutar: siparis.toplamTutar,
      aciklama: 'Satış Faturası: ${siparis.siparisNo}',
    ));

    // Eğer ödenen bir tutar varsa (tamamı veya kısmi), onu da "ODEME_AL" olarak ekleyelim
    if (siparis.odenenTutar > 0) {
      await _cariService.addHareket(CariHareket(
        cariId: siparis.cariId,
        tarih: siparis.tarih.add(const Duration(seconds: 1)), // Aynı saniye çakışmasın diye
        islemTipi: 'ODEME_AL',
        tutar: siparis.odenenTutar,
        aciklama: 'Tahsilat (${siparis.odemeTipi}) - Fatura: ${siparis.siparisNo}',
      ));
    }

    // 3- Sepetteki ürünlerin stoğunu düşüyoruz
    for (var urun in siparis.sepet) {
      if (urun.containsKey('urun_doc_id')) {
        String urunDocId = urun['urun_doc_id'];
        int adet = urun['adet'] ?? 1;
        await _urunService.decreaseStock(urunDocId, adet);
      }
    }

    // 4- Siparişi veritabanına ekle
    Map<String, dynamic> siparisMap = siparis.toMap();
    siparisMap['odendi'] = odendiMi; // Odendi logic

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

  // Spesifik cariye ait siparişler
  Stream<List<Siparis>> getSiparislerByCariId(String cariId) {
    return _db
        .collection('siparisler')
        .where('cari_id', isEqualTo: cariId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Siparis.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Spesifik kasiyerin siparişleri
  Stream<List<Siparis>> getSiparislerByKasiyerId(String kasiyerId) {
    return _db
        .collection('siparisler')
        .where('kasiyer_id', isEqualTo: kasiyerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Siparis.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Belirli bir siparişin kalan borcunu ödeme
  Future<void> paySiparisDebt(String siparisDocId, double odenenMiktar, String odemeTipi) async {
    if (odenenMiktar <= 0) return;

    DocumentSnapshot siparisDoc = await _db.collection('siparisler').doc(siparisDocId).get();
    
    if (siparisDoc.exists) {
      Siparis siparis = Siparis.fromMap(siparisDoc.data() as Map<String, dynamic>, siparisDoc.id);

      // Sadece kalan borcu kadar ödeme yapılabilir.
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

      // Cari'den ödeme alma hareketini kaydet
      await _cariService.addHareket(CariHareket(
        cariId: siparis.cariId,
        tarih: DateTime.now(),
        islemTipi: 'ODEME_AL',
        tutar: gerceklesecekOdeme,
        aciklama: 'Kısmi/Tam Tahsilat ($odemeTipi) - Fatura: ${siparis.siparisNo}',
      ));
    }
  }
}
