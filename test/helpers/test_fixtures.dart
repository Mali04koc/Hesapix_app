import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/urun_model.dart';

/// Firestore test veritabanına standart admin kullanıcısı ekler.
Future<void> seedKullanici(
  FakeFirebaseFirestore db, {
  required String id,
  required String email,
  String adSoyad = 'Test Kullanıcı',
  String rol = 'Admin',
  bool aktif = true,
}) async {
  await db.collection('kullanicilar').doc(id).set({
    'uid': id,
    'ad_soyad': adSoyad,
    'email': email.trim().toLowerCase(),
    'rol': rol,
    'aktif': aktif,
    'olusturulma_tarihi': Timestamp.fromDate(DateTime(2024, 1, 1)),
  });
}

Cari sampleCari({
  String? id,
  String cariKodu = 'C001',
  String firmaAdi = 'Test Firma',
  double bakiye = 0,
}) {
  return Cari(
    id: id,
    cariKodu: cariKodu,
    firmaAdi: firmaAdi,
    vergiNo: '',
    mail: '',
    adres: '',
    bakiye: bakiye,
  );
}

Urun sampleUrun({
  String id = 'u1',
  int urunId = 1,
  String isim = 'Test Ürün',
  double alisFiyat = 100,
  double satisFiyat = 150,
  int stok = 10,
}) {
  return Urun(
    id: id,
    urunId: urunId,
    isim: isim,
    kategoriId: 'k1',
    alisFiyat: alisFiyat,
    satisFiyat: satisFiyat,
    stok: stok,
    barkod: '8690000000001',
    gorsel: '',
    urunKodu: 'UK001',
    tedarikciKodu: '',
  );
}

/// SatisFaturasiOdemePage için gerçek sepet satırı yapısı.
Map<String, dynamic> sampleSatisSepetItem({
  Urun? urun,
  int adet = 1,
  double fiyat = 118.0,
}) {
  final u = urun ?? sampleUrun(satisFiyat: fiyat);
  final ara = fiyat / 1.2;
  final kdv = fiyat - ara;
  return {
    'urun': u,
    'adet': adet,
    'fiyat': fiyat,
    'kdvOrani': 20.0,
    'araToplam': ara * adet,
    'kdvTutar': kdv * adet,
    'toplam': fiyat * adet,
  };
}
