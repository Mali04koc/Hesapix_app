class Tedarikci {
  final String? id; // Firestore document ID
  final int tedarikciId;
  final String isim;
  final String telefon;
  final String adres;
  final double borc; // Bizim tedarikçiye olan borcumuz

  Tedarikci({
    this.id,
    required this.tedarikciId,
    required this.isim,
    required this.telefon,
    required this.adres,
    this.borc = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'tedarikci_id': tedarikciId,
      'isim': isim,
      'telefon': telefon,
      'adres': adres,
      'borc': borc,
    };
  }

  factory Tedarikci.fromMap(Map<String, dynamic> map, String documentId) {
    return Tedarikci(
      id: documentId,
      tedarikciId: map['tedarikci_id'] ?? 0,
      isim: map['isim'] ?? '',
      telefon: map['telefon'] ?? '',
      adres: map['adres'] ?? '',
      borc: (map['borc'] ?? 0).toDouble(),
    );
  }
}
