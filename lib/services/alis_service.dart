import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alis_model.dart';
import '../models/alis_detay_model.dart';
import '../core/database/postgres_connection.dart';

class AlisService {
  final FirebaseFirestore _firestore;

  AlisService({FirebaseFirestore? db}) : _firestore = db ?? FirebaseFirestore.instance;

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
      
      await transaction.set(alisRef, yeniAlis.toMap());

      // Postgres Dual-Write
      try {
        final conn = await PostgresConnection().getConnection();
        await conn.execute(
          'INSERT INTO alislar (id, cari_id, tarih, fatura_no, ara_toplam, kdv_toplam, iskonto, genel_toplam, odeme_turu, odenen_tutar, kasiyer_id) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11)',
          parameters: [yeniAlis.id, yeniAlis.cariId, yeniAlis.tarih, yeniAlis.faturaNo, yeniAlis.araToplam, yeniAlis.kdvToplam, yeniAlis.iskonto, yeniAlis.genelToplam, yeniAlis.odemeTuru, yeniAlis.odenenTutar, yeniAlis.kasiyerId],
        );
      } catch (e) {}

      // Alış Detaylarını Ekle ve Stokları Artır
      for (var item in sepet) {
        final detayRef = _firestore.collection('alis_detaylari').doc();
        final detayMap = item.toMap();
        detayMap['alis_id'] = alisRef.id; // İlişkiyi kur
        await transaction.set(detayRef, detayMap);

        // Postgres Detay Dual-Write
        try {
          final conn = await PostgresConnection().getConnection();
          await conn.execute(
            'INSERT INTO alis_detaylari (id, alis_id, urun_id, urun_adi, miktar, birim_fiyat, kdv_orani, ara_toplam, kdv_tutar, toplam) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10)',
            parameters: [detayRef.id, alisRef.id, item.urunId, item.urunAdi, item.miktar, item.birimFiyat, item.kdvOrani, item.araToplam, item.kdvTutar, item.toplam],
          );
        } catch (e) {}
        
        // STOK ARTIR
        final ref = urunRefs[item.urunId]!;
        final yeniStok = mevcutStoklar[item.urunId]! + item.miktar;
        
        // İsteğe bağlı: Son alış fiyatını da güncelleyebiliriz
        await transaction.update(ref, {
          'stok': yeniStok,
          'alis_fiyati': item.birimFiyat, // Maliyet güncelleme (basit)
        });

        // Postgres Stok Artır
        try {
          final conn = await PostgresConnection().getConnection();
          await conn.execute('UPDATE urunler SET stok = stok + \$1 WHERE id = \$2', parameters: [item.miktar, item.urunId]);
        } catch (e) {}
      }

      // Cari Hareket ve Bakiye Güncelleme (Sadece Açık Hesap ise VEYA kısmi ödeme varsa borç yazılmalı)
      // Satış ekranına benzer olarak: odenenTutar < genelToplam ise, aradaki fark kalan borçtur.
      double kalanBorc = genelToplam - odenenTutar;
      if (kalanBorc < 0) kalanBorc = 0;

      if (kalanBorc > 0 && cariRef != null) {
        final yeniBakiye = mevcutBakiye - kalanBorc;
        await transaction.update(cariRef, {'bakiye': yeniBakiye});

        // Postgres Bakiye
        try {
          final conn = await PostgresConnection().getConnection();
          await conn.execute('UPDATE cariler SET bakiye = bakiye - \$1 WHERE id = \$2', parameters: [kalanBorc, cariId]);
        } catch (e) {}
        
        final hareketRef = _firestore.collection('cari_hareketler').doc();
        final hareketData = {
          'cari_id': cariId,
          'islem_tipi': 'Alış Faturası (Borç)',
          'tarih': DateTime.now(),
          'tutar': kalanBorc,
          'aciklama': '\$faturaNo numaralı Alış Faturası Borç Kaydı',
        };
        await transaction.set(hareketRef, hareketData);

        // Postgres Hareket
        try {
          final conn = await PostgresConnection().getConnection();
          await conn.execute(
            'INSERT INTO cari_hareketler (id, cari_id, islem_tipi, tarih, tutar, aciklama) VALUES (\$1, \$2, \$3, \$4, \$5, \$6)',
            parameters: [hareketRef.id, cariId, 'ALIS', DateTime.now(), kalanBorc, '\$faturaNo numaralı Alış Faturası Borç Kaydı'],
          );
        } catch (e) {}
      }       
      // Nakit/Kart tahsilat kısmı, eğer istersen burada kasa hareketine işlenebilir.
      if (odenenTutar > 0) {
        // Örn: Kasa / Banka Hareketi
      }
      
      return yeniAlis;
    });
  }

  // Tüm Alışları Getirme
  Stream<List<Alis>> getAlislar() {
    return _firestore.collection('alislar').orderBy('tarih', descending: true).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Alis.fromMap(doc.data(), doc.id)).toList());
  }

  // TÜM Alış Detaylarını Getirme (Senkronizasyon için)
  Stream<List<AlisDetay>> getAllAlisDetaylari() {
    return _firestore.collection('alis_detaylari').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => AlisDetay.fromMap(doc.data(), doc.id)).toList());
  }
}
