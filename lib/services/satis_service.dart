import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/satis_model.dart';
import '../models/satis_detay_model.dart';
import '../core/database/postgres_connection.dart';

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
      
      await transaction.set(satisRef, yeniSatis.toMap());

      // Postgres Dual-Write
      try {
        final conn = await PostgresConnection().getConnection();
        await conn.execute(
          'INSERT INTO satislar (id, cari_id, tarih, fatura_no, ara_toplam, kdv_toplam, iskonto, genel_toplam, odeme_turu, odenen_tutar, kasiyer_id) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11)',
          parameters: [yeniSatis.id, yeniSatis.cariId, yeniSatis.tarih, yeniSatis.faturaNo, yeniSatis.araToplam, yeniSatis.kdvToplam, yeniSatis.iskonto, yeniSatis.genelToplam, yeniSatis.odemeTuru, yeniSatis.odenenTutar, yeniSatis.kasiyerId],
        );
      } catch (e) {
        print("Postgres satis hatası: \$e");
      }

      // Satis Detaylarını Ekle
      for (var item in sepet) {
        final detayRef = _firestore.collection('satis_detaylari').doc();
        final detayMap = item.toMap();
        detayMap['satis_id'] = satisRef.id; // İlişkiyi kur
        await transaction.set(detayRef, detayMap);

        // Postgres Detay Dual-Write
        try {
          final conn = await PostgresConnection().getConnection();
          await conn.execute(
            'INSERT INTO satis_detaylari (id, satis_id, urun_id, urun_adi, miktar, birim_fiyat, kdv_orani, ara_toplam, kdv_tutar, toplam) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10)',
            parameters: [detayRef.id, satisRef.id, item.urunId, item.urunAdi, item.miktar, item.birimFiyat, item.kdvOrani, item.araToplam, item.kdvTutar, item.toplam],
          );
        } catch (e) {
          print("Postgres satis detay hatası: \$e");
        }
        
        // Stok Düş
        final ref = urunRefs[item.urunId]!;
        final yeniStok = mevcutStoklar[item.urunId]! - item.miktar;
        await transaction.update(ref, {'stok': yeniStok});

        // Postgres Stok Düş
        try {
          final conn = await PostgresConnection().getConnection();
          await conn.execute('UPDATE urunler SET stok = stok - \$1 WHERE id = \$2', parameters: [item.miktar, item.urunId]);
        } catch (e) {}
      }

      // Cari Hareket ve Bakiye Güncelleme
      // 1. Satış faturası için borçlandırma (Müşteri borcu artar)
      final hareketSatisRef = _firestore.collection('cari_hareketler').doc();
      final hareketSatisData = {
        'cari_id': cariId,
        'islem_tipi': 'SATIS',
        'tarih': DateTime.now(), // FieldValue.serverTimestamp() transaction içinde bazen sorun çıkarabilir, DateTime.now() daha güvenli senkronizasyon için
        'tutar': genelToplam,
        'aciklama': 'Satış Faturası: \$faturaNo',
      };
      await transaction.set(hareketSatisRef, hareketSatisData);

      // Postgres Cari Hareket Dual-Write
      try {
        final conn = await PostgresConnection().getConnection();
        await conn.execute(
          'INSERT INTO cari_hareketler (id, cari_id, islem_tipi, tarih, tutar, aciklama) VALUES (\$1, \$2, \$3, \$4, \$5, \$6)',
          parameters: [hareketSatisRef.id, cariId, 'SATIS', DateTime.now(), genelToplam, 'Satış Faturası: \$faturaNo'],
        );
      } catch (e) {}

      // 2. Ödenen tutar varsa tahsilat hareketi (Müşteri borcu azalır)
      if (odenenTutar > 0) {
        final hareketOdemeRef = _firestore.collection('cari_hareketler').doc();
        final hareketOdemeData = {
          'cari_id': cariId,
          'islem_tipi': 'ODEME_AL',
          'tarih': DateTime.now(),
          'tutar': odenenTutar,
          'aciklama': 'Tahsilat (\$odemeTuru) - Fatura: \$faturaNo',
        };
        await transaction.set(hareketOdemeRef, hareketOdemeData);

        // Postgres Cari Hareket (Ödeme) Dual-Write
        try {
          final conn = await PostgresConnection().getConnection();
          await conn.execute(
            'INSERT INTO cari_hareketler (id, cari_id, islem_tipi, tarih, tutar, aciklama) VALUES (\$1, \$2, \$3, \$4, \$5, \$6)',
            parameters: [hareketOdemeRef.id, cariId, 'ODEME_AL', DateTime.now(), odenenTutar, 'Tahsilat (\$odemeTuru) - Fatura: \$faturaNo'],
          );
        } catch (e) {}
      }

      // 3. Cari bakiyeyi net bakiye ile güncelle
      double netBorcArtisi = genelToplam - odenenTutar;
      double yeniBakiye = mevcutBakiye + netBorcArtisi;
      await transaction.update(cariRef, {'bakiye': yeniBakiye});

      // Postgres Cari Bakiye Güncelleme
      try {
        final conn = await PostgresConnection().getConnection();
        await conn.execute('UPDATE cariler SET bakiye = bakiye + \$1 WHERE id = \$2', parameters: [netBorcArtisi, cariId]);
      } catch (e) {}
      
      return yeniSatis;
    });
  }

  // Tüm Satışları Getirme
  Stream<List<Satis>> getSatislar() {
    return _firestore.collection('satislar').orderBy('tarih', descending: true).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Satis.fromMap(doc.data(), doc.id)).toList());
  }

  // Satış Detaylarını Getirme
  Stream<List<SatisDetay>> getSatisDetaylari(String satisId) {
    return _firestore.collection('satis_detaylari').where('satis_id', isEqualTo: satisId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => SatisDetay.fromMap(doc.data(), doc.id)).toList());
  }

  // TÜM Satış Detaylarını Getirme (Senkronizasyon için)
  Stream<List<SatisDetay>> getAllSatisDetaylari() {
    return _firestore.collection('satis_detaylari').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => SatisDetay.fromMap(doc.data(), doc.id)).toList());
  }
}
