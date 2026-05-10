import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/satis_model.dart';
import '../models/satis_detay_model.dart';

class SatisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      // b. Cari Bilgisi Kontrolü (Açık Hesap ise cariye ihtiyaç var)
      DocumentReference? cariRef;
      double mevcutBakiye = 0.0;
      
      if (odemeTuru == 'Açık Hesap') {
        if (cariId.isEmpty) {
          throw Exception('Açık hesap satışlarında cari seçimi zorunludur!');
        }
        cariRef = _firestore.collection('cariler').doc(cariId);
        final cariSnapshot = await transaction.get(cariRef);
        
        if (!cariSnapshot.exists) {
          throw Exception('Seçilen cari bulunamadı!');
        }
        
        final cariData = cariSnapshot.data() as Map<String, dynamic>;
        mevcutBakiye = (cariData['bakiye'] ?? 0.0).toDouble();
      }

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

      // Cari Hareket ve Bakiye Güncelleme (Sadece Açık Hesap)
      if (odemeTuru == 'Açık Hesap' && cariRef != null) {
        final yeniBakiye = mevcutBakiye + genelToplam; // Müşteri borçlandı, alacağımız arttı
        transaction.update(cariRef, {'bakiye': yeniBakiye});
        
        final hareketRef = _firestore.collection('cari_hareketler').doc();
        final hareketData = {
          'cari_id': cariId,
          'islem_tipi': 'Satış Faturası',
          'tarih': FieldValue.serverTimestamp(),
          'tutar': genelToplam,
          'aciklama': '$faturaNo numaralı Açık Hesap Satış Faturası',
        };
        transaction.set(hareketRef, hareketData);
      } else if (odemeTuru == 'Nakit') {
         // Kasa / Nakit Hareketi istenirse buraya eklenebilir.
         // Şimdilik cari bakiyesini etkilemiyoruz.
      } else if (odemeTuru == 'Kart') {
         // Banka Hareketi istenirse buraya eklenebilir.
      }
      
      return yeniSatis;
    });
  }
}
