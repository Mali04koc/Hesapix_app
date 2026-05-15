import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/services/pdf_service.dart';
import 'package:hesapix_app/models/satis_model.dart';
import 'package:hesapix_app/models/satis_detay_model.dart';
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
      expect(pdfBytes.length, greaterThan(100)); // PDF header varlığını doğrulamak için basit check
    });
  });
}
