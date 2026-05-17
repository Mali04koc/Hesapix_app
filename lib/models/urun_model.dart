class Urun {
  final String? id; // Firestore document ID
  final int urunId;
  final String isim;
  final double alisFiyat;
  final double satisFiyat;
  final int stok;
  final int stokSayisi; // Test uyumluluğu için
  final String barkod;
  final String gorsel;
  final String kategoriId; // Kategori tablosundaki doküman ID'si 
  final String kategori; // Test uyumluluğu için
  final String urunKodu;
  final String tedarikciKodu;

  Urun({
    this.id,
    this.urunId = 0,
    this.isim = '',
    this.alisFiyat = 0.0,
    this.satisFiyat = 0.0,
    this.stok = 0,
    this.stokSayisi = 0,
    this.barkod = '',
    this.gorsel = '',
    this.kategoriId = '',
    this.kategori = '',
    this.urunKodu = '',
    this.tedarikciKodu = '',
  });



  Map<String, dynamic> toMap() {
    return {
      'urun_id': urunId,
      'isim': isim,
      'alis_fiyat': alisFiyat,
      'satis_fiyat': satisFiyat,
      'stok': stokSayisi > 0 ? stokSayisi : stok,
      'barkod': barkod,
      'gorsel': gorsel,
      'kategori_id': kategoriId,
      'kategori_adi': kategori,
      'urun_kodu': urunKodu,
      'tedarikci_kodu': tedarikciKodu,
    };
  }

  factory Urun.fromMap(Map<String, dynamic> map, String documentId) {
    return Urun(
      id: documentId,
      urunId: map['urun_id'] ?? 0,
      isim: map['isim'] ?? '',
      alisFiyat: (map['alis_fiyat'] ?? 0).toDouble(),
      satisFiyat: (map['satis_fiyat'] ?? 0).toDouble(),
      stok: map['stok'] ?? 0,
      stokSayisi: map['stok'] ?? 0,
      barkod: map['barkod'] ?? '',
      gorsel: map['gorsel'] ?? '',
      kategoriId: map['kategori_id'] ?? '',
      kategori: map['kategori_adi'] ?? '',
      urunKodu: map['urun_kodu'] ?? '',
      tedarikciKodu: map['tedarikci_kodu'] ?? '',
    );
  }
}

