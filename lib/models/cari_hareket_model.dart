import 'package:cloud_firestore/cloud_firestore.dart';

class CariHareket {
  final String? id;
  final String cariId;
  final String islemTipi; // Alış Faturası, Satış Faturası, Tahsilat, Ödeme vb.
  final DateTime tarih;
  final double tutar;
  final String aciklama;

  CariHareket({
    this.id,
    required this.cariId,
    required this.islemTipi,
    required this.tarih,
    required this.tutar,
    required this.aciklama,
  });

  Map<String, dynamic> toMap() {
    return {
      'cari_id': cariId,
      'islem_tipi': islemTipi,
      'tarih': Timestamp.fromDate(tarih),
      'tutar': tutar,
      'aciklama': aciklama,
    };
  }

  factory CariHareket.fromMap(Map<String, dynamic> map, String id) {
    return CariHareket(
      id: id,
      cariId: map['cari_id'] ?? '',
      islemTipi: map['islem_tipi'] ?? '',
      tarih: (map['tarih'] as Timestamp).toDate(),
      tutar: (map['tutar'] ?? 0.0).toDouble(),
      aciklama: map['aciklama'] ?? '',
    );
  }
}
