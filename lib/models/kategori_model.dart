class Kategori {
  final String? id; // Firestore document ID
  final int kategoriId;
  final String isim;
  final int cesit;
  final int adet;

  Kategori({
    this.id,
    required this.kategoriId,
    required this.isim,
    this.cesit = 0,
    this.adet = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'kategori_id': kategoriId,
      'isim': isim,
      'cesit': cesit,
      'adet': adet,
    };
  }

  factory Kategori.fromMap(Map<String, dynamic> map, String documentId) {
    return Kategori(
      id: documentId,
      kategoriId: map['kategori_id'] ?? 0,
      isim: map['isim'] ?? '',
      cesit: map['cesit'] ?? map['adet'] ?? 0, // Fallback to old 'adet' if 'cesit' is missing for backward comp
      adet: map['adet'] ?? 0,
    );
  }
}
