import 'package:flutter/material.dart';
import '../models/satis_detay_model.dart';
import '../models/urun_model.dart';

class SatisProvider with ChangeNotifier {
  List<SatisDetay> _sepet = [];
  String _seciliCariId = '';
  String _odemeTuru = 'Nakit';
  double _iskonto = 0.0;
  bool _kdvDahil = true;

  List<SatisDetay> get sepet => _sepet;
  String get seciliCariId => _seciliCariId;
  String get odemeTuru => _odemeTuru;
  double get iskonto => _iskonto;
  bool get kdvDahil => _kdvDahil;

  double get araToplam {
    return _sepet.fold(0, (sum, item) => sum + item.araToplam);
  }

  double get kdvToplam {
    return _sepet.fold(0, (sum, item) => sum + item.kdvTutar);
  }

  double get genelToplam {
    return (araToplam + kdvToplam) - _iskonto;
  }

  void setCariId(String cariId) {
    _seciliCariId = cariId;
    notifyListeners();
  }

  void setOdemeTuru(String tur) {
    _odemeTuru = tur;
    notifyListeners();
  }

  void setIskonto(double deger) {
    _iskonto = deger;
    notifyListeners();
  }
  
  void setKdvDahil(bool dahil) {
    _kdvDahil = dahil;
    // Sepeti yeniden hesapla
    for (int i = 0; i < _sepet.length; i++) {
       _sepet[i] = _hesaplaDetay(_sepet[i].urunId, _sepet[i].urunAdi, _sepet[i].miktar, _sepet[i].birimFiyat, _sepet[i].kdvOrani);
    }
    notifyListeners();
  }

  SatisDetay _hesaplaDetay(String urunId, String urunAdi, int miktar, double fiyat, double kdvOrani) {
    double birimAraToplam = 0;
    double birimKdvTutar = 0;

    if (_kdvDahil) {
      // Fiyat KDV Dahil ise, kdv hariç tutarı bul
      birimAraToplam = fiyat / (1 + (kdvOrani / 100));
      birimKdvTutar = fiyat - birimAraToplam;
    } else {
      // Fiyat KDV Hariç ise
      birimAraToplam = fiyat;
      birimKdvTutar = fiyat * (kdvOrani / 100);
    }

    double araToplam = birimAraToplam * miktar;
    double kdvTutar = birimKdvTutar * miktar;
    double toplam = (birimAraToplam + birimKdvTutar) * miktar;

    return SatisDetay(
      satisId: '', // Satış tamamlandığında verilecek
      urunId: urunId,
      urunAdi: urunAdi,
      miktar: miktar,
      birimFiyat: fiyat,
      kdvOrani: kdvOrani,
      araToplam: araToplam,
      kdvTutar: kdvTutar,
      toplam: toplam,
    );
  }

  void sepeteEkle(Urun urun, {int eklenecekMiktar = 1}) {
    // Sepette var mı?
    int index = _sepet.indexWhere((item) => item.urunId == urun.id);
    if (index >= 0) {
      // Miktarı artır
      int yeniMiktar = _sepet[index].miktar + eklenecekMiktar;
      _sepet[index] = _hesaplaDetay(
        urun.id!, 
        urun.isim, 
        yeniMiktar, 
        urun.satisFiyat, 
        18.0 // Varsayılan KDV %18, istenirse ürün tablosuna eklenebilir
      );
    } else {
      // Yeni ekle
      _sepet.add(_hesaplaDetay(
        urun.id!, 
        urun.isim, 
        eklenecekMiktar, 
        urun.satisFiyat, 
        18.0
      ));
    }
    notifyListeners();
  }

  void sepettenCikar(String urunId) {
    _sepet.removeWhere((item) => item.urunId == urunId);
    notifyListeners();
  }

  void miktarGuncelle(String urunId, int yeniMiktar) {
    if (yeniMiktar <= 0) {
      sepettenCikar(urunId);
      return;
    }
    int index = _sepet.indexWhere((item) => item.urunId == urunId);
    if (index >= 0) {
      _sepet[index] = _hesaplaDetay(
        _sepet[index].urunId,
        _sepet[index].urunAdi,
        yeniMiktar,
        _sepet[index].birimFiyat,
        _sepet[index].kdvOrani,
      );
      notifyListeners();
    }
  }

  void sepetiTemizle() {
    _sepet.clear();
    _seciliCariId = '';
    _odemeTuru = 'Nakit';
    _iskonto = 0.0;
    notifyListeners();
  }
}
