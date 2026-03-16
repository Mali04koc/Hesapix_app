class Kasiyer {
  final String? id;
  final String isim;
  final String soyad;
  final String kullaniciAdi;
  final String parola;
  final double maas;
  final int toplamSatisAdeti;
  final double toplamSatisTutari;

  Kasiyer({
    this.id,
    required this.isim,
    required this.soyad,
    required this.kullaniciAdi,
    required this.parola,
    required this.maas,
    this.toplamSatisAdeti = 0,
    this.toplamSatisTutari = 0.0,
  });

  // Firestore'a veri gönderirken Map'e çevirir
  Map<String, dynamic> toMap() {
    return {
      'isim': isim,
      'soyad': soyad,
      'kullanici_adi': kullaniciAdi,
      'parola': parola,
      'maas': maas,
      'toplam_satis_adeti': toplamSatisAdeti,
      'toplam_satis_tutari': toplamSatisTutari,
    };
  }

  // Firestore'dan gelen veriyi Kasiyer objesine çevirir
  factory Kasiyer.fromMap(Map<String, dynamic> map, String documentId) {
    return Kasiyer(
      id: documentId,
      isim: map['isim'] ?? '',
      soyad: map['soyad'] ?? '',
      kullaniciAdi: map['kullanici_adi'] ?? '',
      parola: map['parola'] ?? '',
      maas: (map['maas'] ?? 0).toDouble(),
      toplamSatisAdeti: map['toplam_satis_adeti'] ?? 0,
      toplamSatisTutari: (map['toplam_satis_tutari'] ?? 0.0).toDouble(),
    );
  }
}
