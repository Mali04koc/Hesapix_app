class UrunAlis {
  final String? id; // Firestore document ID
  final int alisId;
  final int urunId;
  final int tedarikciId;
  final double urunAlisFiyat;
  final int adet;
  final double toplamTutar;
  final double odenenTutar;
  final DateTime tarih;

  UrunAlis({
    this.id,
    required this.alisId,
    required this.urunId,
    required this.tedarikciId,
    required this.urunAlisFiyat,
    required this.adet,
    required this.toplamTutar,
    required this.odenenTutar,
    required this.tarih,
  });

  Map<String, dynamic> toMap() {
    return {
      'alis_id': alisId,
      'urun_id': urunId,
      'tedarikci_id': tedarikciId,
      'urun_alis_fiyat': urunAlisFiyat,
      'adet': adet,
      'toplam_tutar': toplamTutar,
      'odenen_tutar': odenenTutar,
      'tarih': tarih.toIso8601String(),
    };
  }

  factory UrunAlis.fromMap(Map<String, dynamic> map, String documentId) {
    return UrunAlis(
      id: documentId,
      alisId: map['alis_id'] ?? 0,
      urunId: map['urun_id'] ?? 0,
      tedarikciId: map['tedarikci_id'] ?? 0,
      urunAlisFiyat: (map['urun_alis_fiyat'] ?? 0).toDouble(),
      adet: map['adet'] ?? 0,
      toplamTutar: (map['toplam_tutar'] ?? 0).toDouble(),
      odenenTutar: (map['odenen_tutar'] ?? 0).toDouble(),
      tarih: map['tarih'] != null ? DateTime.parse(map['tarih']) : DateTime.now(),
    );
  }
}
