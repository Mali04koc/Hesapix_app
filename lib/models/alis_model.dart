import 'package:cloud_firestore/cloud_firestore.dart';

class Alis {
  final String? id;
  final String cariId;
  final DateTime tarih;
  final String faturaNo;
  final double araToplam;
  final double kdvToplam;
  final double iskonto;
  final double genelToplam;
  final String odemeTuru; // "Nakit", "Kart", "Açık Hesap"
  final double odenenTutar;
  final String kasiyerId;

  Alis({
    this.id,
    required this.cariId,
    required this.tarih,
    required this.faturaNo,
    required this.araToplam,
    required this.kdvToplam,
    required this.iskonto,
    required this.genelToplam,
    required this.odemeTuru,
    required this.odenenTutar,
    required this.kasiyerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'cari_id': cariId,
      'tarih': Timestamp.fromDate(tarih),
      'fatura_no': faturaNo,
      'ara_toplam': araToplam,
      'kdv_toplam': kdvToplam,
      'iskonto': iskonto,
      'genel_toplam': genelToplam,
      'odeme_turu': odemeTuru,
      'odenen_tutar': odenenTutar,
      'kasiyer_id': kasiyerId,
    };
  }

  factory Alis.fromMap(Map<String, dynamic> map, String documentId) {
    return Alis(
      id: documentId,
      cariId: map['cari_id'] ?? '',
      tarih: (map['tarih'] as Timestamp).toDate(),
      faturaNo: map['fatura_no'] ?? '',
      araToplam: (map['ara_toplam'] ?? 0.0).toDouble(),
      kdvToplam: (map['kdv_toplam'] ?? 0.0).toDouble(),
      iskonto: (map['iskonto'] ?? 0.0).toDouble(),
      genelToplam: (map['genel_toplam'] ?? 0.0).toDouble(),
      odemeTuru: map['odeme_turu'] ?? '',
      odenenTutar: (map['odenen_tutar'] ?? map['genel_toplam'] ?? 0.0).toDouble(),
      kasiyerId: map['kasiyer_id'] ?? '',
    );
  }
}
