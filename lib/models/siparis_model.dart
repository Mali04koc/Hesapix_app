class Siparis {
  final String? id; // Firestore document ID
  final int siparisId;
  final int musteriId;
  final int kasiyerId;
  final DateTime tarih;
  final double toplamTutar;
  final double odenenTutar;
  final bool odendi;
  final String odemeTipi; // Nakit, Kredi Kartı, Veresiye, Parçalı vs.
  final List<Map<String, dynamic>> sepet; // Satılan ürünlerin listesi

  Siparis({
    this.id,
    required this.siparisId,
    required this.musteriId,
    required this.kasiyerId,
    required this.tarih,
    required this.toplamTutar,
    required this.odenenTutar,
    required this.odemeTipi,
    required this.sepet,
    bool? odendi,
  }) : odendi = odendi ?? ((toplamTutar - odenenTutar) <= 0);

  Map<String, dynamic> toMap() {
    bool otomatikOdendi = (toplamTutar - odenenTutar) <= 0;
    
    return {
      'siparis_id': siparisId,
      'musteri_id': musteriId,
      'kasiyer_id': kasiyerId,
      'tarih': tarih.toIso8601String(), // DateTime formatı için
      'toplam_tutar': toplamTutar,
      'odenen_tutar': odenenTutar,
      'odendi': otomatikOdendi,
      'odeme_tipi': odemeTipi,
      'sepet': sepet,
    };
  }

  factory Siparis.fromMap(Map<String, dynamic> map, String documentId) {
    return Siparis(
      id: documentId,
      siparisId: map['siparis_id'] ?? 0,
      musteriId: map['musteri_id'] ?? 0,
      kasiyerId: map['kasiyer_id'] ?? 0,
      tarih: map['tarih'] != null ? DateTime.parse(map['tarih']) : DateTime.now(),
      toplamTutar: (map['toplam_tutar'] ?? 0).toDouble(),
      odenenTutar: (map['odenen_tutar'] ?? 0).toDouble(),
      odendi: map['odendi'] ?? false,
      odemeTipi: map['odeme_tipi'] ?? 'Nakit',
      sepet: map['sepet'] != null ? List<Map<String, dynamic>>.from(map['sepet']) : [],
    );
  }
}
