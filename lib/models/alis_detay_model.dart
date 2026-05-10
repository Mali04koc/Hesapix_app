class AlisDetay {
  final String? id;
  final String alisId;
  final String urunId;
  final String urunAdi;
  final int miktar;
  final double birimFiyat;
  final double kdvOrani;
  final double araToplam;
  final double kdvTutar;
  final double toplam;

  AlisDetay({
    this.id,
    required this.alisId,
    required this.urunId,
    required this.urunAdi,
    required this.miktar,
    required this.birimFiyat,
    required this.kdvOrani,
    required this.araToplam,
    required this.kdvTutar,
    required this.toplam,
  });

  Map<String, dynamic> toMap() {
    return {
      'alis_id': alisId,
      'urun_id': urunId,
      'urun_adi': urunAdi,
      'miktar': miktar,
      'birim_fiyat': birimFiyat,
      'kdv_orani': kdvOrani,
      'ara_toplam': araToplam,
      'kdv_tutar': kdvTutar,
      'toplam': toplam,
    };
  }

  factory AlisDetay.fromMap(Map<String, dynamic> map, String documentId) {
    return AlisDetay(
      id: documentId,
      alisId: map['alis_id'] ?? '',
      urunId: map['urun_id'] ?? '',
      urunAdi: map['urun_adi'] ?? '',
      miktar: map['miktar'] ?? 0,
      birimFiyat: (map['birim_fiyat'] ?? 0.0).toDouble(),
      kdvOrani: (map['kdv_orani'] ?? 0.0).toDouble(),
      araToplam: (map['ara_toplam'] ?? 0.0).toDouble(),
      kdvTutar: (map['kdv_tutar'] ?? 0.0).toDouble(),
      toplam: (map['toplam'] ?? 0.0).toDouble(),
    );
  }
}
