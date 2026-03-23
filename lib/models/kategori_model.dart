class Kategori {
  final String? id; // Firestore document ID
  final String isim;
  final int adet;

  Kategori({
    this.id,
    required this.isim,
    this.adet = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'isim': isim,
      'adet': adet,
    };
  }

  factory Kategori.fromMap(Map<String, dynamic> map, String documentId) {
    return Kategori(
      id: documentId,
      isim: map['isim'] ?? '',
      adet: map['adet'] ?? 0,
    );
  }
}
