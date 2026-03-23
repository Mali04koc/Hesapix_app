class Masraf {
  final String? id; // Firestore document ID
  final int masrafId;
  final String tip; // elektrik, su, doğalgaz, kira, vergi, diğer
  final double tutar;
  final DateTime tarih;
  final String aciklama;

  Masraf({
    this.id,
    required this.masrafId,
    required this.tip,
    required this.tutar,
    required this.tarih,
    required this.aciklama,
  });

  Map<String, dynamic> toMap() {
    return {
      'masraf_id': masrafId,
      'tip': tip,
      'tutar': tutar,
      'tarih': tarih.toIso8601String(),
      'aciklama': aciklama,
    };
  }

  factory Masraf.fromMap(Map<String, dynamic> map, String documentId) {
    return Masraf(
      id: documentId,
      masrafId: map['masraf_id'] ?? 0,
      tip: map['tip'] ?? 'diğer',
      tutar: (map['tutar'] ?? 0).toDouble(),
      tarih: map['tarih'] != null ? DateTime.parse(map['tarih']) : DateTime.now(),
      aciklama: map['aciklama'] ?? '',
    );
  }
}
