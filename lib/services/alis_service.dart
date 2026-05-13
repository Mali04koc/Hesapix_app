import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alis_model.dart';
import '../models/alis_detay_model.dart';

class AlisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Yeni Fatura Numarası Üretme (Basit bir zaman bazlı ID)
  String _generateFaturaNo() {
    final now = DateTime.now();
    return "AL-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}";
  }

  Future<Alis> alisYap({
    required String cariId,
    required double araToplam,
    required double kdvToplam,
    required double iskonto,
    required double genelToplam,
    required String odemeTuru,
    required double odenenTutar,
    required String kasiyerId,
    required List<AlisDetay> sepet,
  }) async {
    if (sepet.isEmpty) {
      throw Exception('Sepet boş olamaz!');
    }
    if (cariId.isEmpty) {
      throw Exception('Alış işlemlerinde tedarikçi seçimi zorunludur!');
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
      }

      // b. Cari Bilgisi Kontrolü (Açık Hesap ise cariye ihtiyaç var)
      DocumentReference? cariRef;
      double mevcutBakiye = 0.0;
      
      if (odemeTuru == 'Açık Hesap') {
        cariRef = _firestore.collection('cariler').doc(cariId);
        final cariSnapshot = await transaction.get(cariRef);
        
        if (!cariSnapshot.exists) {
          throw Exception('Seçilen tedarikçi bulunamadı!');
        }
        
        final cariData = cariSnapshot.data() as Map<String, dynamic>;
        mevcutBakiye = (cariData['bakiye'] ?? 0.0).toDouble();
      }

      // 2. İşlemleri Uygula
      
      // Alış Kaydını Oluştur
      final faturaNo = _generateFaturaNo();
      final alisRef = _firestore.collection('alislar').doc();
      final yeniAlis = Alis(
        id: alisRef.id,
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
      
      transaction.set(alisRef, yeniAlis.toMap());

      // Alış Detaylarını Ekle ve Stokları Artır
      for (var item in sepet) {
        final detayRef = _firestore.collection('alis_detaylari').doc();
        final detayMap = item.toMap();
        detayMap['alis_id'] = alisRef.id; // İlişkiyi kur
        transaction.set(detayRef, detayMap);
        
        // STOK ARTIR
        final ref = urunRefs[item.urunId]!;
        final yeniStok = mevcutStoklar[item.urunId]! + item.miktar;
        
        // İsteğe bağlı: Son alış fiyatını da güncelleyebiliriz
        transaction.update(ref, {
          'stok': yeniStok,
          'alis_fiyati': item.birimFiyat, // Maliyet güncelleme (basit)
        });
      }

      // Cari Hareket ve Bakiye Güncelleme (Sadece Açık Hesap ise VEYA kısmi ödeme varsa borç yazılmalı)
      // Satış ekranına benzer olarak: odenenTutar < genelToplam ise, aradaki fark kalan borçtur.
      double kalanBorc = genelToplam - odenenTutar;
      if (kalanBorc < 0) kalanBorc = 0;

      if (kalanBorc > 0 && cariRef != null) {
        // Alış işleminde biz tedarikçiye borçlanırız, yani bakiye düşer (eksi yönde)
        // Cari bizim için alacaklı olur
        final yeniBakiye = mevcutBakiye - kalanBorc;
        transaction.update(cariRef, {'bakiye': yeniBakiye});
        
        final hareketRef = _firestore.collection('cari_hareketler').doc();
        final hareketData = {
          'cari_id': cariId,
          'islem_tipi': 'Alış Faturası (Borç)',
          'tarih': FieldValue.serverTimestamp(),
          'tutar': kalanBorc,
          'aciklama': '$faturaNo numaralı Alış Faturası Borç Kaydı',
        };
        transaction.set(hareketRef, hareketData);
      } 
      
      // Nakit/Kart tahsilat kısmı, eğer istersen burada kasa hareketine işlenebilir.
      if (odenenTutar > 0) {
        // Örn: Kasa / Banka Hareketi
      }
      
      return yeniAlis;
    });
  }
}
