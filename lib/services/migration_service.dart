import 'package:hesapix_app/services/firebase_urun_service.dart';
import 'package:hesapix_app/services/postgres/postgres_urun_service.dart';
import 'package:hesapix_app/services/firebase_cari_service.dart';
import 'package:hesapix_app/services/postgres/postgres_cari_service.dart';
import 'package:hesapix_app/services/kategori_service.dart';
import 'package:hesapix_app/services/satis_service.dart';
import 'package:hesapix_app/services/alis_service.dart';
import 'package:hesapix_app/services/user_service.dart';
import 'package:hesapix_app/core/database/postgres_connection.dart';
import 'package:hesapix_app/models/satis_model.dart';
import 'package:hesapix_app/models/satis_detay_model.dart';
import 'package:hesapix_app/models/alis_model.dart';
import 'package:hesapix_app/models/alis_detay_model.dart';
import 'package:hesapix_app/models/app_user_model.dart';

class MigrationService {
  static final FirebaseUrunService _firebaseUrun = FirebaseUrunService();
  static final PostgresUrunService _postgresUrun = PostgresUrunService();
  static final FirebaseCariService _firebaseCari = FirebaseCariService();
  static final PostgresCariService _postgresCari = PostgresCariService();
  static final KategoriService _kategoriService = KategoriService();
  static final SatisService _satisService = SatisService();
  static final AlisService _alisService = AlisService();
  static final UserService _userService = UserService();
  static final PostgresConnection _postgres = PostgresConnection();

  static Future<void> syncTwoWay() async {
    print("Senkronizasyon: Başlıyor...");
    final conn = await _postgres.getConnection();

    // 0. Tabloları Hazırla
    print("Senkronizasyon: Tablolar kontrol ediliyor...");
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS satislar (
        id VARCHAR(255) PRIMARY KEY,
        cari_id VARCHAR(255),
        tarih TIMESTAMP,
        fatura_no VARCHAR(255),
        ara_toplam DECIMAL,
        kdv_toplam DECIMAL,
        iskonto DECIMAL,
        genel_toplam DECIMAL,
        odeme_turu VARCHAR(50),
        odenen_tutar DECIMAL,
        kasiyer_id VARCHAR(255)
      )
    ''');
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS satis_detaylari (
        id VARCHAR(255) PRIMARY KEY,
        satis_id VARCHAR(255),
        urun_id VARCHAR(255),
        urun_adi VARCHAR(255),
        miktar INT,
        birim_fiyat DECIMAL,
        kdv_orani DECIMAL,
        ara_toplam DECIMAL,
        kdv_tutar DECIMAL,
        toplam DECIMAL
      )
    ''');
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS alislar (
        id VARCHAR(255) PRIMARY KEY,
        cari_id VARCHAR(255),
        tarih TIMESTAMP,
        fatura_no VARCHAR(255),
        ara_toplam DECIMAL,
        kdv_toplam DECIMAL,
        iskonto DECIMAL,
        genel_toplam DECIMAL,
        odeme_turu VARCHAR(50),
        odenen_tutar DECIMAL,
        kasiyer_id VARCHAR(255)
      )
    ''');
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS alis_detaylari (
        id VARCHAR(255) PRIMARY KEY,
        alis_id VARCHAR(255),
        urun_id VARCHAR(255),
        urun_adi VARCHAR(255),
        miktar INT,
        birim_fiyat DECIMAL,
        kdv_orani DECIMAL,
        ara_toplam DECIMAL,
        kdv_tutar DECIMAL,
        toplam DECIMAL
      )
    ''');

      await conn.execute('''
        CREATE TABLE IF NOT EXISTS kullanicilar (
          id VARCHAR(255) PRIMARY KEY,
          uid VARCHAR(255),
          ad_soyad VARCHAR(255),
          email VARCHAR(255),
          rol VARCHAR(50),
          aktif BOOLEAN,
          son_giris_tarihi TIMESTAMP,
          olusturulma_tarihi TIMESTAMP
        )
      ''');

      // 1. Kategorileri Senkronize Et
    print("Senkronizasyon: Kategoriler...");
    final firebaseKategoriler = await _kategoriService.getKategoriler().first.timeout(const Duration(seconds: 15));
    for (final kat in firebaseKategoriler) {
      try {
        await _kategoriService.addKategori(kat);
      } catch (e) {}
    }

    // 2. Ürünleri Senkronize Et
    print("Senkronizasyon: Ürünler...");
    final firebaseUrunler = await _firebaseUrun.getUrunler().first.timeout(const Duration(seconds: 15));
    final postgresUrunler = await _postgresUrun.getUrunler().first.timeout(const Duration(seconds: 15));
    for (final urun in firebaseUrunler) {
      if (!postgresUrunler.any((p) => p.id == urun.id)) {
        try { await _postgresUrun.addUrun(urun); } catch (e) {}
      }
    }
    for (final urun in postgresUrunler) {
      if (!firebaseUrunler.any((f) => f.id == urun.id)) {
        try { await _firebaseUrun.addUrun(urun); } catch (e) {}
      }
    }

    // 3. Carileri Senkronize Et
    print("Senkronizasyon: Cariler...");
    final firebaseCariler = await _firebaseCari.getCariler().first.timeout(const Duration(seconds: 15));
    final postgresCariler = await _postgresCari.getCariler().first.timeout(const Duration(seconds: 15));
    for (final cari in firebaseCariler) {
      if (!postgresCariler.any((p) => p.id == cari.id)) {
        try { await _postgresCari.addCari(cari); } catch (e) {}
      }
    }
    for (final cari in postgresCariler) {
      if (!firebaseCariler.any((f) => f.id == cari.id)) {
        try { await _firebaseCari.addCari(cari); } catch (e) {}
      }
    }

    // 4. Cari Hareketleri Senkronize Et
    print("Senkronizasyon: Cari Hareketler...");
    final firebaseHareketler = await _firebaseCari.getAllHareketler().first.timeout(const Duration(seconds: 15));
    final postgresHareketler = await _postgresCari.getAllHareketler().first.timeout(const Duration(seconds: 15));
    for (final h in firebaseHareketler) {
      if (!postgresHareketler.any((p) => p.id == h.id)) {
        try { await _postgresCari.addHareket(h); } catch (e) {}
      }
    }
    for (final h in postgresHareketler) {
      if (!firebaseHareketler.any((f) => f.id == h.id)) {
        try { await _firebaseCari.addHareket(h); } catch (e) {}
      }
    }

    // 5. Satışları Senkronize Et
    print("Senkronizasyon: Satışlar...");
    final firebaseSatislar = await _satisService.getSatislar().first.timeout(const Duration(seconds: 15));
    final postgresSatisResult = await conn.execute('SELECT id FROM satislar');
    final postgresSatisIds = postgresSatisResult.map((r) => r[0].toString()).toSet();

    for (final s in firebaseSatislar) {
      if (!postgresSatisIds.contains(s.id)) {
        try {
          await conn.execute(
            'INSERT INTO satislar (id, cari_id, tarih, fatura_no, ara_toplam, kdv_toplam, iskonto, genel_toplam, odeme_turu, odenen_tutar, kasiyer_id) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11)',
            parameters: [s.id, s.cariId, s.tarih, s.faturaNo, s.araToplam, s.kdvToplam, s.iskonto, s.genelToplam, s.odemeTuru, s.odenenTutar, s.kasiyerId],
          );
        } catch (e) {}
      }
    }

    // 6. Satış Detaylarını Senkronize Et
    print("Senkronizasyon: Satış Detayları...");
    final firebaseSatisDetaylar = await _satisService.getAllSatisDetaylari().first.timeout(const Duration(seconds: 15));
    final postgresDetayResult = await conn.execute('SELECT id FROM satis_detaylari');
    final postgresDetayIds = postgresDetayResult.map((r) => r[0].toString()).toSet();

    for (final d in firebaseSatisDetaylar) {
      if (!postgresDetayIds.contains(d.id)) {
        try {
          await conn.execute(
            'INSERT INTO satis_detaylari (id, satis_id, urun_id, urun_adi, miktar, birim_fiyat, kdv_orani, ara_toplam, kdv_tutar, toplam) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10)',
            parameters: [d.id, d.satisId, d.urunId, d.urunAdi, d.miktar, d.birimFiyat, d.kdvOrani, d.araToplam, d.kdvTutar, d.toplam],
          );
        } catch (e) {}
      }
    }

    // 7. Alışları Senkronize Et
    print("Senkronizasyon: Alışlar...");
    final firebaseAlislar = await _alisService.getAlislar().first.timeout(const Duration(seconds: 15));
    final postgresAlisResult = await conn.execute('SELECT id FROM alislar');
    final postgresAlisIds = postgresAlisResult.map((r) => r[0].toString()).toSet();

    for (final a in firebaseAlislar) {
      if (!postgresAlisIds.contains(a.id)) {
        try {
          await conn.execute(
            'INSERT INTO alislar (id, cari_id, tarih, fatura_no, ara_toplam, kdv_toplam, iskonto, genel_toplam, odeme_turu, odenen_tutar, kasiyer_id) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11)',
            parameters: [a.id, a.cariId, a.tarih, a.faturaNo, a.araToplam, a.kdvToplam, a.iskonto, a.genelToplam, a.odemeTuru, a.odenenTutar, a.kasiyerId],
          );
        } catch (e) {}
      }
    }

    // 8. Alış Detaylarını Senkronize Et
    print("Senkronizasyon: Alış Detayları...");
    final firebaseAlisDetaylar = await _alisService.getAllAlisDetaylari().first.timeout(const Duration(seconds: 15));
    final postgresAlisDetayResult = await conn.execute('SELECT id FROM alis_detaylari');
    final postgresAlisDetayIds = postgresAlisDetayResult.map((r) => r[0].toString()).toSet();

    for (final d in firebaseAlisDetaylar) {
      if (!postgresAlisDetayIds.contains(d.id)) {
        try {
          await conn.execute(
            'INSERT INTO alis_detaylari (id, alis_id, urun_id, urun_adi, miktar, birim_fiyat, kdv_orani, ara_toplam, kdv_tutar, toplam) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10)',
            parameters: [d.id, d.alisId, d.urunId, d.urunAdi, d.miktar, d.birimFiyat, d.kdvOrani, d.araToplam, d.kdvTutar, d.toplam],
          );
        } catch (e) { print("Alış detay senkronizasyon hatası: $e"); }
      }
    }

    // 9. Kullanıcıları Senkronize Et
    print("Senkronizasyon: Kullanıcılar...");
    try {
      final firebaseUsers = await _userService.streamUsers().first.timeout(const Duration(seconds: 15));
      final postgresUsersResult = await conn.execute('SELECT id FROM kullanicilar');
      final postgresUserIds = postgresUsersResult.map((r) => r[0].toString()).toSet();

      for (final u in firebaseUsers) {
        if (!postgresUserIds.contains(u.id)) {
          try {
            await conn.execute(
              'INSERT INTO kullanicilar (id, uid, ad_soyad, email, rol, aktif, son_giris_tarihi, olusturulma_tarihi) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8)',
              parameters: [u.id, u.uid, u.adSoyad, u.email, u.rol, u.aktif, u.sonGirisTarihi, u.olusturulmaTarihi],
            );
          } catch (e) {}
        }
      }
    } catch (e) { print("Kullanıcı senkronizasyon hatası: $e"); }

    print("Senkronizasyon: Başarıyla tamamlandı.");
  }
}
