import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/satis_model.dart';
import '../models/satis_detay_model.dart';

class SatisService {
  final FirebaseFirestore _firestore;

  SatisService({FirebaseFirestore? db}) : _firestore = db ?? FirebaseFirestore.instance;

  // Yeni Fatura Numarası Üretme (Basit bir zaman bazlı ID)
  String _generateFaturaNo() {
    final now = DateTime.now();
    return "FT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}";
  }

  Future<Satis> satisYap({
    required String cariId,
    required double araToplam,
    required double kdvToplam,
    required double iskonto,
    required double genelToplam,
    required String odemeTuru,
    required double odenenTutar,
    required String kasiyerId,
    required List<SatisDetay> sepet,
  }) async {
    if (sepet.isEmpty) {
      throw Exception('Sepet boş olamaz!');
    }

    // 1. Transaction Başlat
    return await _firestore.runTransaction((transaction) async {
      // a. Stok Kontrolleri İçin Ürün Referanslarını Oku
      Map<String, DocumentReference> urunRefs = {};
      Map<String, int> mevcutStoklar = {};
      
      for (var item in sepet) {
        final ref = _firestore.collection('urunler').doc(item.urunId);
        urunRefs[item.urunId] = ref;
        final snapshot = await transaction.get(ref);
        
        if (!snapshot.exists) {
          throw Exception('Ürün bulunamadı: ${item.urunAdi}');
        }
        
        final urunData = snapshot.data() as Map<String, dynamic>;
        final stok = urunData['stok'] ?? 0;
        mevcutStoklar[item.urunId] = stok;
        
        if (stok < item.miktar) {
          throw Exception('Yetersiz stok: ${item.urunAdi} (Mevcut: $stok)');
        }
      }

      // b. Cari Bilgisi Kontrolü
      if (cariId.isEmpty) {
        throw Exception('Satış işlemlerinde cari seçimi zorunludur!');
      }
      DocumentReference cariRef = _firestore.collection('cariler').doc(cariId);
      final cariSnapshot = await transaction.get(cariRef);
      
      if (!cariSnapshot.exists) {
        throw Exception('Seçilen cari bulunamadı!');
      }
      
      final cariData = cariSnapshot.data() as Map<String, dynamic>;
      double mevcutBakiye = (cariData['bakiye'] ?? 0.0).toDouble();

      // 2. İşlemleri Uygula
      
      // Satis Kaydını Oluştur
      final faturaNo = _generateFaturaNo();
      final satisRef = _firestore.collection('satislar').doc();
      final yeniSatis = Satis(
        id: satisRef.id,
        cariId: cariId,
        tarih: DateTime.now(),
        faturaNo: faturaNo,
        araToplam: araToplam,
        kdvToplam: kdvToplam,
        iskonto: iskonto,
        genelToplam: genelToplam,
        odemeTuru: odemeTuru,
        odenenTutar: odenenTutar,
        kasiyerId: kasiyerId,
      );
      
      transaction.set(satisRef, yeniSatis.toMap());

      // Satis Detaylarını Ekle
      for (var item in sepet) {
        final detayRef = _firestore.collection('satis_detaylari').doc();
        final detayMap = item.toMap();
        detayMap['satis_id'] = satisRef.id; // İlişkiyi kur
        transaction.set(detayRef, detayMap);
        
        // Stok Düş
        final ref = urunRefs[item.urunId]!;
        final yeniStok = mevcutStoklar[item.urunId]! - item.miktar;
        transaction.update(ref, {'stok': yeniStok});
      }

      // Cari Hareket ve Bakiye Güncelleme
      // 1. Satış faturası için borçlandırma (Müşteri borcu artar)
      final hareketSatisRef = _firestore.collection('cari_hareketler').doc();
      final hareketSatisData = {
        'cari_id': cariId,
        'islem_tipi': 'SATIS',
        'tarih': FieldValue.serverTimestamp(),
        'tutar': genelToplam,
        'aciklama': 'Satış Faturası: $faturaNo',
      };
      transaction.set(hareketSatisRef, hareketSatisData);

      // 2. Ödenen tutar varsa tahsilat hareketi (Müşteri borcu azalır)
      if (odenenTutar > 0) {
        final hareketOdemeRef = _firestore.collection('cari_hareketler').doc();
        final hareketOdemeData = {
          'cari_id': cariId,
          'islem_tipi': 'ODEME_AL',
          'tarih': FieldValue.serverTimestamp(),
          'tutar': odenenTutar,
          'aciklama': 'Tahsilat ($odemeTuru) - Fatura: $faturaNo',
        };
        transaction.set(hareketOdemeRef, hareketOdemeData);
      }

      // 3. Cari bakiyeyi net bakiye ile güncelle
      double netBorcArtisi = genelToplam - odenenTutar;
      double yeniBakiye = mevcutBakiye + netBorcArtisi;
      transaction.update(cariRef, {'bakiye': yeniBakiye});
      
      return yeniSatis;
    });
  }
}
