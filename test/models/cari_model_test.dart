import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/cari_model.dart';

void main() {
  group('Cari Modeli Testleri', () {
    test('toMap() doğru bir Map döndürmeli', () {
      final tarih = DateTime(2023, 1, 1);
      final cari = Cari(
        id: 'cari1',
        cariKodu: 'C001',
        firmaAdi: 'Test Firma',
        vergiNo: '1234567890',
        mail: 'test@test.com',
        adres: 'Test Adres',
        bakiye: 500.0,
        sonIslemTarihi: tarih,
      );

      final map = cari.toMap();

      expect(map['cari_kodu'], 'C001');
      expect(map['firma_adi'], 'Test Firma');
      expect(map['vergi_no'], '1234567890');
      expect(map['mail'], 'test@test.com');
      expect(map['adres'], 'Test Adres');
      expect(map['bakiye'], 500.0);
      expect(map['son_islem_tarihi'], isA<Timestamp>());
      expect((map['son_islem_tarihi'] as Timestamp).toDate(), tarih);
    });

    test('fromMap() doğru bir Cari nesnesi oluşturmalı', () {
      final tarih = DateTime(2023, 1, 1);
      final map = {
        'cari_kodu': 'C001',
        'firma_adi': 'Test Firma',
        'vergi_no': '1234567890',
        'mail': 'test@test.com',
        'adres': 'Test Adres',
        'bakiye': 500.0,
        'son_islem_tarihi': Timestamp.fromDate(tarih),
      };

      final cari = Cari.fromMap(map, 'cari1');

      expect(cari.id, 'cari1');
      expect(cari.cariKodu, 'C001');
      expect(cari.firmaAdi, 'Test Firma');
      expect(cari.vergiNo, '1234567890');
      expect(cari.mail, 'test@test.com');
      expect(cari.adres, 'Test Adres');
      expect(cari.bakiye, 500.0);
      expect(cari.sonIslemTarihi, tarih);
    });

    test('fromMap() null son_islem_tarihi ile çalışmalı', () {
      final map = {
        'cari_kodu': 'C001',
        'firma_adi': 'Test Firma',
        'vergi_no': '1234567890',
        'mail': 'test@test.com',
        'adres': 'Test Adres',
        'bakiye': 500.0,
        'son_islem_tarihi': null,
      };

      final cari = Cari.fromMap(map, 'cari1');
      expect(cari.sonIslemTarihi, isNull);
    });
  });
}
