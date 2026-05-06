class Siparis {
  final String? id; // Firestore document ID
  final String siparisNo; // Random benzersiz numara (Örn: SP-123456)
  final String cariId;
  final String cariAdi;
  final String kasiyerId;
  final DateTime tarih;
  final double toplamTutar;
  final double odenenTutar;
  final bool odendi;
  final String odemeTipi; // Nakit, Kredi Kartı, Veresiye, Kısmi vb.
  final List<Map<String, dynamic>> sepet; // Satılan ürünlerin listesi

  Siparis({
    this.id,
    required this.siparisNo,
    required this.cariId,
    required this.cariAdi,
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
      'siparis_no': siparisNo,
      'cari_id': cariId,
      'cari_adi': cariAdi,
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
      siparisNo: map['siparis_no'] ?? '',
      cariId: map['cari_id'] ?? '',
      cariAdi: map['cari_adi'] ?? '',
      kasiyerId: map['kasiyer_id'] ?? '',
      tarih: map['tarih'] != null ? DateTime.parse(map['tarih']) : DateTime.now(),
      toplamTutar: (map['toplam_tutar'] ?? 0).toDouble(),
      odenenTutar: (map['odenen_tutar'] ?? 0).toDouble(),
      odendi: map['odendi'] ?? false,
      odemeTipi: map['odeme_tipi'] ?? 'Nakit',
      sepet: map['sepet'] != null ? List<Map<String, dynamic>>.from(map['sepet']) : [],
    );
  }
}
