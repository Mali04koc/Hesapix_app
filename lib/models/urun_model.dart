class Urun {
  final String? id; // Firestore document ID
  final int urunId;
  final String isim;
  final double alisFiyat;
  final double satisFiyat;
  final int stok;
  final String barkod;
  final String gorsel;
  final String kategoriId; // Kategori tablosundaki doküman ID'si 

  Urun({
    this.id,
    required this.urunId,
    required this.isim,
    required this.alisFiyat,
    required this.satisFiyat,
    required this.stok,
    required this.barkod,
    required this.gorsel,
    required this.kategoriId,
  });

  Map<String, dynamic> toMap() {
    return {
      'urun_id': urunId,
      'isim': isim,
      'alis_fiyat': alisFiyat,
      'satis_fiyat': satisFiyat,
      'stok': stok,
      'barkod': barkod,
      'gorsel': gorsel,
      'kategori_id': kategoriId,
    };
  }

  factory Urun.fromMap(Map<String, dynamic> map, String documentId) {
    return Urun(
      id: documentId,
      urunId: map['urun_id'] ?? 0,
      isim: map['isim'] ?? '',
      alisFiyat: (map['alis_fiyat'] ?? 0).toDouble(),
      satisFiyat: (map['satis_fiyat'] ?? 0).toDouble(),
      stok: map['stok'] ?? 0,
      barkod: map['barkod'] ?? '',
      gorsel: map['gorsel'] ?? '',
      kategoriId: map['kategori_id'] ?? '',
    );
  }
}
