import 'package:cloud_firestore/cloud_firestore.dart';

class Cari {
  final String? id;
  final String cariKodu;
  final String firmaAdi;
  final String vergiNo;
  final String mail;
  final String adres;
  final double bakiye;
  final DateTime? sonIslemTarihi;

  Cari({
    this.id,
    required this.cariKodu,
    required this.firmaAdi,
    required this.vergiNo,
    required this.mail,
    required this.adres,
    this.bakiye = 0.0,
    this.sonIslemTarihi,
  });

  Map<String, dynamic> toMap() {
    return {
      'cari_kodu': cariKodu,
      'firma_adi': firmaAdi,
      'vergi_no': vergiNo,
      'mail': mail,
      'adres': adres,
      'bakiye': bakiye,
      'son_islem_tarihi': sonIslemTarihi != null ? Timestamp.fromDate(sonIslemTarihi!) : null,
    };
  }

  factory Cari.fromMap(Map<String, dynamic> map, String id) {
    return Cari(
      id: id,
      cariKodu: map['cari_kodu'] ?? '',
      firmaAdi: map['firma_adi'] ?? '',
      vergiNo: map['vergi_no'] ?? '',
      mail: map['mail'] ?? '',
      adres: map['adres'] ?? '',
      bakiye: (map['bakiye'] ?? 0.0).toDouble(),
      sonIslemTarihi: map['son_islem_tarihi'] != null ? (map['son_islem_tarihi'] as Timestamp).toDate() : null,
    );
  }
}
