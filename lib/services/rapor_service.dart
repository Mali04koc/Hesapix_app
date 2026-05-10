import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/satis_model.dart';
import '../models/satis_detay_model.dart';
import '../models/alis_model.dart';
import '../models/alis_detay_model.dart';
import '../models/cari_hareket_model.dart';
import '../models/cari_model.dart';
import '../models/urun_model.dart';
import '../models/app_user_model.dart';

class RaporService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Satis>> getSatislar(DateTime baslangic, DateTime bitis) async {
    final snapshot = await _firestore
        .collection('satislar')
        .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(baslangic))
        .where('tarih', isLessThanOrEqualTo: Timestamp.fromDate(bitis))
        .get();

    return snapshot.docs.map((doc) => Satis.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<SatisDetay>> getSatisDetaylari(DateTime baslangic, DateTime bitis) async {
    final satislar = await getSatislar(baslangic, bitis);
    final satisIdListesi = satislar.map((s) => s.id).whereType<String>().toList();

    if (satisIdListesi.isEmpty) return [];

    List<SatisDetay> tumDetaylar = [];
    for (var i = 0; i < satisIdListesi.length; i += 10) {
      final chunk = satisIdListesi.sublist(i, i + 10 > satisIdListesi.length ? satisIdListesi.length : i + 10);
      final snapshot = await _firestore
          .collection('satis_detaylari')
          .where('satis_id', whereIn: chunk)
          .get();
      
      tumDetaylar.addAll(snapshot.docs.map((doc) => SatisDetay.fromMap(doc.data(), doc.id)));
    }
    return tumDetaylar;
  }

  Future<List<Alis>> getAlislar(DateTime baslangic, DateTime bitis) async {
    final snapshot = await _firestore
        .collection('alislar')
        .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(baslangic))
        .where('tarih', isLessThanOrEqualTo: Timestamp.fromDate(bitis))
        .get();

    return snapshot.docs.map((doc) => Alis.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<AlisDetay>> getAlisDetaylari(DateTime baslangic, DateTime bitis) async {
    final alislar = await getAlislar(baslangic, bitis);
    final alisIdListesi = alislar.map((s) => s.id).whereType<String>().toList();

    if (alisIdListesi.isEmpty) return [];

    List<AlisDetay> tumDetaylar = [];
    for (var i = 0; i < alisIdListesi.length; i += 10) {
      final chunk = alisIdListesi.sublist(i, i + 10 > alisIdListesi.length ? alisIdListesi.length : i + 10);
      final snapshot = await _firestore
          .collection('alis_detaylari')
          .where('alis_id', whereIn: chunk)
          .get();
      
      tumDetaylar.addAll(snapshot.docs.map((doc) => AlisDetay.fromMap(doc.data(), doc.id)));
    }
    return tumDetaylar;
  }

  Future<List<CariHareket>> getCariHareketler(String cariId, DateTime baslangic, DateTime bitis) async {
    final snapshot = await _firestore
        .collection('cari_hareketler')
        .where('cari_id', isEqualTo: cariId)
        .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(baslangic))
        .where('tarih', isLessThanOrEqualTo: Timestamp.fromDate(bitis))
        .orderBy('tarih')
        .get();

    return snapshot.docs.map((doc) => CariHareket.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<CariHareket>> getTumCariHareketler(DateTime baslangic, DateTime bitis) async {
    final snapshot = await _firestore
        .collection('cari_hareketler')
        .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(baslangic))
        .where('tarih', isLessThanOrEqualTo: Timestamp.fromDate(bitis))
        .orderBy('tarih')
        .get();

    return snapshot.docs.map((doc) => CariHareket.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<Cari>> getCariler() async {
    final snapshot = await _firestore.collection('cariler').get();
    return snapshot.docs.map((doc) => Cari.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<Urun>> getTumUrunler() async {
    final snapshot = await _firestore.collection('urunler').get();
    return snapshot.docs.map((doc) => Urun.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<AppUserModel>> getKasiyerler() async {
    final snapshot = await _firestore.collection('kullanicilar').get(); 
    try {
      return snapshot.docs.map((doc) => AppUserModel.fromDoc(doc)).toList();
    } catch(e) {
      return [];
    }
  }

  // Özel Tahsilat/Ödeme Filtresi
  Future<List<CariHareket>> getTahsilatOdemeHareketleri(DateTime baslangic, DateTime bitis) async {
    final snapshot = await _firestore
        .collection('cari_hareketler')
        .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(baslangic))
        .where('tarih', isLessThanOrEqualTo: Timestamp.fromDate(bitis))
        .orderBy('tarih', descending: true)
        .get();

    final tumHareketler = snapshot.docs.map((doc) => CariHareket.fromMap(doc.data(), doc.id)).toList();
    // Tahsilat veya Ödeme kelimesi geçenleri filtrele
    return tumHareketler.where((h) => 
      h.islemTipi.toLowerCase().contains('tahsilat') || 
      h.islemTipi.toLowerCase().contains('ödeme') ||
      h.aciklama.toLowerCase().contains('tahsilat') ||
      h.aciklama.toLowerCase().contains('ödeme')
    ).toList();
  }
}
