import 'package:cloud_firestore/cloud_firestore.dart';

class CariHareket {
  final String? id;
  final String cariId;
  final String islemTuru; // Satış Faturası, Tahsilat vb. (Testlerde bu isim geçiyor)
  final String islemTipi; // Mevcut kullanım
  final String evrakNo;
  final DateTime tarih;
  final double tutar;
  final String aciklama;

  CariHareket({
    this.id,
    this.cariId = '',
    this.islemTuru = '',
    this.islemTipi = '',
    this.evrakNo = '',
    DateTime? tarih,
    this.tutar = 0.0,
    this.aciklama = '',
  }) : tarih = tarih ?? DateTime.now();


  Map<String, dynamic> toMap() {
    return {
      'cari_id': cariId,
      'islem_turu': islemTuru,
      'islem_tipi': islemTipi.isEmpty ? islemTuru : islemTipi,
      'evrak_no': evrakNo,
      'tarih': Timestamp.fromDate(tarih),
      'tutar': tutar,
      'aciklama': aciklama,
    };
  }

  factory CariHareket.fromMap(Map<String, dynamic> map, String id) {
    return CariHareket(
      id: id,
      cariId: map['cari_id'] ?? '',
      islemTuru: map['islem_turu'] ?? map['islem_tipi'] ?? '',
      islemTipi: map['islem_tipi'] ?? '',
      evrakNo: map['evrak_no'] ?? '',
      tarih: (map['tarih'] as Timestamp).toDate(),
      tutar: (map['tutar'] ?? 0.0).toDouble(),
      aciklama: map['aciklama'] ?? '',
    );
  }
}

