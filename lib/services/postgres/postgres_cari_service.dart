import 'dart:async';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';
import 'package:hesapix_app/services/interfaces/i_cari_service.dart';
import 'package:hesapix_app/core/database/postgres_connection.dart';
import 'package:uuid/uuid.dart';

class PostgresCariService implements ICariService {
  final _db = PostgresConnection();
  final _uuid = const Uuid();

  @override
  Future<void> addCari(Cari cari) async {
    final conn = await _db.getConnection();
    final id = cari.id ?? _uuid.v4();
    
    await conn.execute(
      r'''
      INSERT INTO cariler (id, cari_kodu, firma_adi, vergi_no, mail, adres, bakiye, son_islem_tarihi)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      ''',
      parameters: [
        id,
        cari.cariKodu,
        cari.firmaAdi,
        cari.vergiNo,
        cari.mail,
        cari.adres,
        cari.bakiye,
        cari.sonIslemTarihi,
      ],
    );
  }

  @override
  Future<List<Cari>> cariAra(String arama) async {
    final conn = await _db.getConnection();
    final query = '%${arama.toLowerCase()}%';
    final result = await conn.execute(
      r'''
      SELECT * FROM cariler 
      WHERE LOWER(firma_adi) LIKE $1 OR LOWER(cari_kodu) LIKE $1
      ''',
      parameters: [query],
    );

    return result.map((row) => _mapRowToCari(row.toColumnMap())).toList();
  }

  @override
  Stream<List<Cari>> getCariler() {
    return _getCarilerStream().asBroadcastStream();
  }

  Stream<List<Cari>> _getCarilerStream() async* {
    // Postgres doesn't naturally support Streams like Firestore.
    // For now, we fetch once and yield. 
    // In a real app, you might want to implement polling or LISTEN/NOTIFY.
    final conn = await _db.getConnection();
    final result = await conn.execute('SELECT * FROM cariler ORDER BY firma_adi');
    yield result.map((row) => _mapRowToCari(row.toColumnMap())).toList();
  }

  @override
  Future<void> updateCari(Cari cari) async {
    if (cari.id == null) return;
    final conn = await _db.getConnection();
    await conn.execute(
      r'''
      UPDATE cariler 
      SET cari_kodu = $1, firma_adi = $2, vergi_no = $3, mail = $4, adres = $5, bakiye = $6, son_islem_tarihi = $7
      WHERE id = $8
      ''',
      parameters: [
        cari.cariKodu,
        cari.firmaAdi,
        cari.vergiNo,
        cari.mail,
        cari.adres,
        cari.bakiye,
        cari.sonIslemTarihi,
        cari.id,
      ],
    );
  }

  @override
  Future<void> deleteCari(String id) async {
    final conn = await _db.getConnection();
    await conn.execute(r'DELETE FROM cariler WHERE id = $1', parameters: [id]);
  }

  @override
  Future<void> addHareket(CariHareket hareket) async {
    final conn = await _db.getConnection();
    final id = hareket.id ?? _uuid.v4();

    await conn.runTx((ctx) async {
      // Hareket ekle
      await ctx.execute(
        r'''
        INSERT INTO cari_hareketler (id, cari_id, islem_tipi, tarih, tutar, aciklama)
        VALUES ($1, $2, $3, $4, $5, $6)
        ''',
        parameters: [
          id,
          hareket.cariId,
          hareket.islemTipi,
          hareket.tarih,
          hareket.tutar,
          hareket.aciklama,
        ],
      );

      // Bakiye hesapla
      double bakiyeEtkisi = 0;
      switch (hareket.islemTipi) {
        case "SATIS":
          bakiyeEtkisi = hareket.tutar;
          break;
        case "ALIS":
          bakiyeEtkisi = -hareket.tutar;
          break;
        case "ODEME_AL":
          bakiyeEtkisi = -hareket.tutar;
          break;
        case "ODEME_YAP":
          bakiyeEtkisi = hareket.tutar;
          break;
      }

      // Cari bakiyesini güncelle
      await ctx.execute(
        r'''
        UPDATE cariler 
        SET bakiye = bakiye + $1, son_islem_tarihi = CURRENT_TIMESTAMP
        WHERE id = $2
        ''',
        parameters: [bakiyeEtkisi, hareket.cariId],
      );
    });
  }

  @override
  Stream<List<CariHareket>> getHareketler(String cariId) {
    return _getHareketlerStream(cariId).asBroadcastStream();
  }

  Stream<List<CariHareket>> _getHareketlerStream(String cariId) async* {
    final conn = await _db.getConnection();
    final result = await conn.execute(
      r'SELECT * FROM cari_hareketler WHERE cari_id = $1 ORDER BY tarih DESC',
      parameters: [cariId]
    );
    yield result.map((row) => _mapRowToHareket(row.toColumnMap())).toList();
  }

  @override
  Stream<List<CariHareket>> getAllHareketler() {
    return _getAllHareketlerStream().asBroadcastStream();
  }

  Stream<List<CariHareket>> _getAllHareketlerStream() async* {
    final conn = await _db.getConnection();
    final result = await conn.execute('SELECT * FROM cari_hareketler ORDER BY tarih DESC LIMIT 50');
    yield result.map((row) => _mapRowToHareket(row.toColumnMap())).toList();
  }

  // --- Yardımcı Mapper Metodları ---
  Cari _mapRowToCari(Map<String, dynamic> row) {
    return Cari(
      id: row['id'] as String?,
      cariKodu: row['cari_kodu'] as String? ?? '',
      firmaAdi: row['firma_adi'] as String? ?? '',
      vergiNo: row['vergi_no'] as String? ?? '',
      mail: row['mail'] as String? ?? '',
      adres: row['adres'] as String? ?? '',
      bakiye: double.parse(row['bakiye'].toString()),
      sonIslemTarihi: row['son_islem_tarihi'] as DateTime?,
    );
  }

  CariHareket _mapRowToHareket(Map<String, dynamic> row) {
    return CariHareket(
      id: row['id'] as String?,
      cariId: row['cari_id'] as String? ?? '',
      islemTipi: row['islem_tipi'] as String? ?? '',
      tarih: row['tarih'] as DateTime,
      tutar: double.parse(row['tutar'].toString()),
      aciklama: row['aciklama'] as String? ?? '',
    );
  }
}
