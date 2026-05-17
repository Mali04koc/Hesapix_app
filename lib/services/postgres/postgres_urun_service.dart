import 'dart:async';
import 'package:hesapix_app/models/urun_model.dart';
import 'package:hesapix_app/services/interfaces/i_urun_service.dart';
import 'package:hesapix_app/core/database/postgres_connection.dart';
import 'package:uuid/uuid.dart';

class PostgresUrunService implements IUrunService {
  final _db = PostgresConnection();
  final _uuid = const Uuid();

  @override
  Future<void> addUrun(Urun urun) async {
    final conn = await _db.getConnection();
    final id = urun.id ?? _uuid.v4();
    
    // Postgres'te urun_id SERIAL olduğu için veritabanı otomatik atayacak.
    // Ancak RETURNING kullanarak atanmış id'yi alabiliriz.
    await conn.execute(
      r'''
      INSERT INTO urunler (id, isim, alis_fiyat, satis_fiyat, stok, barkod, gorsel, kategori_id, urun_kodu, tedarikci_kodu)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      ''',
      parameters: [
        id,
        urun.isim,
        urun.alisFiyat,
        urun.satisFiyat,
        urun.stok,
        urun.barkod,
        urun.gorsel,
        urun.kategoriId,
        urun.urunKodu,
        urun.tedarikciKodu,
      ],
    );
  }

  @override
  Stream<List<Urun>> getUrunler() {
    return _getUrunlerStream().asBroadcastStream();
  }

  Stream<List<Urun>> _getUrunlerStream() async* {
    final conn = await _db.getConnection();
    final result = await conn.execute('SELECT * FROM urunler ORDER BY isim');
    yield result.map((row) => _mapRowToUrun(row.toColumnMap())).toList();
  }

  @override
  Future<void> updateUrun(Urun urun) async {
    if (urun.id == null) return;
    final conn = await _db.getConnection();
    await conn.execute(
      r'''
      UPDATE urunler 
      SET isim = $1, alis_fiyat = $2, satis_fiyat = $3, stok = $4, barkod = $5, gorsel = $6, kategori_id = $7, urun_kodu = $8, tedarikci_kodu = $9
      WHERE id = $10
      ''',
      parameters: [
        urun.isim,
        urun.alisFiyat,
        urun.satisFiyat,
        urun.stok,
        urun.barkod,
        urun.gorsel,
        urun.kategoriId,
        urun.urunKodu,
        urun.tedarikciKodu,
        urun.id,
      ],
    );
  }

  @override
  Future<void> deleteUrun(String id) async {
    final conn = await _db.getConnection();
    await conn.execute(r'DELETE FROM urunler WHERE id = $1', parameters: [id]);
  }

  @override
  Future<void> decreaseStock(String urunId, int miktar) async {
    final conn = await _db.getConnection();
    await conn.execute(
      r'''
      UPDATE urunler 
      SET stok = stok - $1 
      WHERE id = $2 AND stok >= $1
      ''',
      parameters: [miktar, urunId],
    );
    // TODO: Burada stok yetersizse exception fırlatılabilir (affected rows kontrolü ile).
  }

  @override
  Future<void> increaseStockByUrunId(int urunIdInt, int miktar) async {
    final conn = await _db.getConnection();
    await conn.execute(
      r'''
      UPDATE urunler 
      SET stok = stok + $1 
      WHERE urun_id = $2
      ''',
      parameters: [miktar, urunIdInt],
    );
  }

  @override
  Future<List<Urun>> urunAra(String arama) async {
    final conn = await _db.getConnection();
    final query = '%${arama.toLowerCase()}%';
    final result = await conn.execute(
      r'''
      SELECT * FROM urunler 
      WHERE LOWER(isim) LIKE $1 OR LOWER(urun_kodu) LIKE $1 OR LOWER(barkod) LIKE $1
      ''',
      parameters: [query],
    );
    return result.map((row) => _mapRowToUrun(row.toColumnMap())).toList();
  }

  Urun _mapRowToUrun(Map<String, dynamic> row) {
    return Urun(
      id: row['id'] as String?,
      urunId: row['urun_id'] as int? ?? 0,
      isim: row['isim'] as String? ?? '',
      alisFiyat: double.parse((row['alis_fiyat'] ?? 0).toString()),
      satisFiyat: double.parse((row['satis_fiyat'] ?? 0).toString()),
      stok: row['stok'] as int? ?? 0,
      barkod: row['barkod'] as String? ?? '',
      gorsel: row['gorsel'] as String? ?? '',
      kategoriId: row['kategori_id'] as String? ?? '',
      urunKodu: row['urun_kodu'] as String? ?? '',
      tedarikciKodu: row['tedarikci_kodu'] as String? ?? '',
    );
  }
}
