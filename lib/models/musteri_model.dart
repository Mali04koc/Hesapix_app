class Musteri {
  final String? id; // Firestore document ID
  final int musteriId;
  final String musteriIsim;
  final String musteriTel;
  final String musteriAdres;
  final double musteriBorc;

  Musteri({
    this.id,
    required this.musteriId,
    required this.musteriIsim,
    required this.musteriTel,
    required this.musteriAdres,
    required this.musteriBorc,
  });

  Map<String, dynamic> toMap() {
    return {
      'musteri_id': musteriId,
      'musteri_isim': musteriIsim,
      'musteri_tel': musteriTel,
      'musteri_adres': musteriAdres,
      'musteri_borc': musteriBorc,
    };
  }

  factory Musteri.fromMap(Map<String, dynamic> map, String documentId) {
    return Musteri(
      id: documentId,
      musteriId: map['musteri_id'] ?? 0,
      musteriIsim: map['musteri_isim'] ?? '',
      musteriTel: map['musteri_tel'] ?? '',
      musteriAdres: map['musteri_adres'] ?? '',
      musteriBorc: (map['musteri_borc'] ?? 0).toDouble(),
    );
  }
}
