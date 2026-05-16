import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/kategori_model.dart';
import 'package:hesapix_app/core/database/postgres_connection.dart';
import 'package:uuid/uuid.dart';

class KategoriService {
  final FirebaseFirestore _db;
  final PostgresConnection _postgres = PostgresConnection();
  final Uuid _uuid = const Uuid();

  KategoriService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  // Yeni Kategori Ekleme
  Future<void> addKategori(Kategori kategori) async {
    QuerySnapshot query = await _db
        .collection('kategoriler')
        .orderBy('kategori_id', descending: true)
        .limit(1)
        .get();

    int nextId = 1;
    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data() as Map<String, dynamic>;
      final currentMax = data['kategori_id'] as int? ?? 0;
      nextId = currentMax + 1;
    }

    final newKategori = Kategori(
      id: kategori.id ?? _uuid.v4(),
      kategoriId: nextId,
      isim: kategori.isim,
      adet: kategori.adet,
    );

    // 1. Firebase'e ekle
    await _db.collection('kategoriler').doc(newKategori.id).set(newKategori.toMap());

    // 2. Postgres'e arka planda ekle (Dual-write)
    try {
      final conn = await _postgres.getConnection();
      // Tablo yoksa oluştur
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS kategoriler (
          id VARCHAR(255) PRIMARY KEY,
          kategori_id INT,
          isim VARCHAR(255),
          adet INT
        )
      ''');
      await conn.execute(
        'INSERT INTO kategoriler (id, kategori_id, isim, adet) VALUES (\$1, \$2, \$3, \$4)',
        parameters: [newKategori.id, newKategori.kategoriId, newKategori.isim, newKategori.adet],
      );
    } catch (e) {
      print("Postgres kategori ekleme hatası: \$e");
    }
  }

  // Tüm Kategorileri Getirme (SADECE FIREBASE - kullanıcının istediği gibi)
  Stream<List<Kategori>> getKategoriler() {
    return _db.collection('kategoriler').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Kategori.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Kategori Güncelleme
  Future<void> updateKategori(Kategori kategori) async {
    if (kategori.id != null) {
      // 1. Firebase
      await _db
          .collection('kategoriler')
          .doc(kategori.id)
          .update(kategori.toMap());

      // 2. Postgres
      try {
        final conn = await _postgres.getConnection();
        await conn.execute(
          'UPDATE kategoriler SET isim = \$1, adet = \$2 WHERE id = \$3',
          parameters: [kategori.isim, kategori.adet, kategori.id],
        );
      } catch (e) {
        print("Postgres kategori güncelleme hatası: \$e");
      }
    }
  }

  // Kategori Silme
  Future<void> deleteKategori(String id) async {
    // 1. Firebase
    await _db.collection('kategoriler').doc(id).delete();

    // 2. Postgres
    try {
      final conn = await _postgres.getConnection();
      await conn.execute('DELETE FROM kategoriler WHERE id = \$1', parameters: [id]);
    } catch (e) {
      print("Postgres kategori silme hatası: \$e");
    }
  }
}
