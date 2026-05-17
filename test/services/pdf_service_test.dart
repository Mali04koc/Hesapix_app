import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/services/pdf_service.dart';
import 'package:hesapix_app/models/satis_model.dart';
import 'package:hesapix_app/models/satis_detay_model.dart';
import 'package:hesapix_app/models/alis_model.dart';
import 'package:hesapix_app/models/alis_detay_model.dart';
import 'package:hesapix_app/models/cari_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PdfService Testleri', () {
    test('generateSatisFaturasiPdf() geçerli bir Uint8List döndürmeli', () async {
      final satis = Satis(
        cariId: 'c1',
        tarih: DateTime.now(),
        faturaNo: 'FAT01',
        araToplam: 100.0,
        kdvToplam: 18.0,
        iskonto: 0.0,
        genelToplam: 118.0,
        odemeTuru: 'Nakit',
        odenenTutar: 118.0,
        kasiyerId: 'Admin',
      );

      final detaylar = [
        SatisDetay(
          satisId: 's1',
          urunId: 'u1',
          urunAdi: 'Test Ürün',
          miktar: 1,
          birimFiyat: 100.0,
          kdvOrani: 18.0,
          araToplam: 100.0,
          kdvTutar: 18.0,
          toplam: 118.0,
        )
      ];

      final cari = Cari(
        cariKodu: 'C01',
        firmaAdi: 'Test Cari',
        vergiNo: '',
        mail: '',
        adres: '',
      );

      final pdfBytes = await PdfService.generateSatisFaturasiPdf(
        satis: satis,
        detaylar: detaylar,
        cari: cari,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));
      // PDF magic bytes: %PDF
      expect(String.fromCharCodes(pdfBytes.take(4)), '%PDF');
    });

    test('generateAlisFaturasiPdf() geçerli bir Uint8List döndürmeli', () async {
      final alis = Alis(
        cariId: 'c1',
        tarih: DateTime.now(),
        faturaNo: 'ALIS01',
        araToplam: 200.0,
        kdvToplam: 36.0,
        iskonto: 0.0,
        genelToplam: 236.0,
        odemeTuru: 'Açık Hesap',
        odenenTutar: 0.0,
        kasiyerId: 'Admin',
      );

      final detaylar = [
        AlisDetay(
          alisId: 'a1',
          urunId: 'u1',
          urunAdi: 'Tedarik Ürün',
          miktar: 2,
          birimFiyat: 100.0,
          kdvOrani: 18.0,
          araToplam: 200.0,
          kdvTutar: 36.0,
          toplam: 236.0,
        ),
      ];

      final tedarikci = Cari(
        cariKodu: 'T01',
        firmaAdi: 'Tedarikçi A.Ş.',
        vergiNo: '123',
        mail: '',
        adres: '',
      );

      final pdfBytes = await PdfService.generateAlisFaturasiPdf(
        alis: alis,
        detaylar: detaylar,
        tedarikci: tedarikci,
      );

      expect(pdfBytes, isNotEmpty);
      expect(String.fromCharCodes(pdfBytes.take(4)), '%PDF');
    });
  });
}
