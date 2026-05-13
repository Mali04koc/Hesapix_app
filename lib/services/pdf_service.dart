import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:hesapix_app/models/satis_model.dart';
import 'package:hesapix_app/models/satis_detay_model.dart';
import 'package:hesapix_app/models/alis_model.dart';
import 'package:hesapix_app/models/alis_detay_model.dart';
import 'package:hesapix_app/models/cari_model.dart';

class PdfService {
  static final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  static final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  // Satış Faturası (PDF) Oluştur
  static Future<Uint8List> generateSatisFaturasiPdf({
    required Satis satis,
    required List<SatisDetay> detaylar,
    required Cari cari,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('SATIŞ FATURASI', satis.faturaNo, satis.tarih),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(cari, 'Müşteri Bilgileri'),
              pw.SizedBox(height: 20),
               _buildSatisItemsTable(detaylar),
              pw.SizedBox(height: 10),
              _buildTotals(
                araToplam: satis.araToplam, 
                iskonto: satis.iskonto, 
                kdv: satis.kdvToplam, 
                genelToplam: satis.genelToplam, 
                odemeTuru: satis.odemeTuru,
                odenenTutar: satis.odenenTutar,
                cari: cari,
              ),
              pw.SizedBox(height: 40),
              _buildFooter(satis.kasiyerId),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Alış Faturası (PDF) Oluştur
  static Future<Uint8List> generateAlisFaturasiPdf({
    required Alis alis,
    required List<AlisDetay> detaylar,
    required Cari tedarikci,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('ALIŞ FATURASI', alis.faturaNo, alis.tarih),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(tedarikci, 'Tedarikçi Bilgileri'),
              pw.SizedBox(height: 20),
              _buildAlisItemsTable(detaylar),
              pw.SizedBox(height: 10),
              _buildTotals(
                araToplam: alis.araToplam, 
                iskonto: alis.iskonto, 
                kdv: alis.kdvToplam, 
                genelToplam: alis.genelToplam, 
                odemeTuru: alis.odemeTuru,
                odenenTutar: alis.odenenTutar,
                cari: tedarikci,
              ),
              pw.SizedBox(height: 40),
              _buildFooter(alis.kasiyerId),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Ortak Header
  static pw.Widget _buildHeader(String baslik, String faturaNo, DateTime tarih) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('HESAPİX', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
            pw.Text('Her zaman bekleriz', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(baslik, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Fatura No: $faturaNo', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Tarih: ${_dateFormat.format(tarih)}', style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  // Ortak Müşteri/Tedarikçi Bilgisi
  static pw.Widget _buildCustomerInfo(Cari cari, String baslik) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(baslik, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
          pw.SizedBox(height: 4),
          pw.Text(cari.firmaAdi, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if (cari.vergiNo.isNotEmpty) pw.Text('Vergi No: ${cari.vergiNo}', style: const pw.TextStyle(fontSize: 12)),
          if (cari.adres.isNotEmpty) pw.Text('Adres: ${cari.adres}', style: const pw.TextStyle(fontSize: 12)),
          if (cari.mail.isNotEmpty) pw.Text('E-posta: ${cari.mail}', style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // Satış Tablosu
  static pw.Widget _buildSatisItemsTable(List<SatisDetay> detaylar) {
    return pw.TableHelper.fromTextArray(
      headers: ['Ürün Adı', 'Miktar', 'Birim Fiyat', 'İskonto', 'KDV', 'Toplam'],
      data: detaylar.map((d) {
        return [
          d.urunAdi,
          d.miktar.toString(),
          _currencyFormat.format(d.birimFiyat),
          _currencyFormat.format(0.0), // iskonto satır bazında yok
          '%${d.kdvOrani.toStringAsFixed(0)}',
          _currencyFormat.format(d.toplam),
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
    );
  }

  // Alış Tablosu
  static pw.Widget _buildAlisItemsTable(List<AlisDetay> detaylar) {
    return pw.TableHelper.fromTextArray(
      headers: ['Ürün Adı', 'Miktar', 'Birim Fiyat', 'İskonto', 'KDV', 'Toplam'],
      data: detaylar.map((d) {
        return [
          d.urunAdi,
          d.miktar.toString(),
          _currencyFormat.format(d.birimFiyat),
          _currencyFormat.format(0.0), // iskonto satır bazında yok
          '%${d.kdvOrani.toStringAsFixed(0)}',
          _currencyFormat.format(d.toplam),
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
    );
  }

  // Toplamlar Alanı
  static pw.Widget _buildTotals({
    required double araToplam,
    required double iskonto,
    required double kdv,
    required double genelToplam,
    required String odemeTuru,
    required double odenenTutar,
    required Cari cari,
  }) {
    double kalanBorc = genelToplam - odenenTutar;
    if (kalanBorc < 0) kalanBorc = 0;

    bool isGenericCari = cari.cariKodu == '111';

    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 200,
              child: pw.Column(
                children: [
                  _buildTotalRow('Ara Toplam:', araToplam),
                  if (iskonto > 0) _buildTotalRow('İskonto:', -iskonto),
                  _buildTotalRow('KDV Toplamı:', kdv),
                  pw.Divider(color: PdfColors.grey400),
                  _buildTotalRow('Genel Toplam:', genelToplam, isBold: true),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(color: PdfColors.grey300, thickness: 1, borderStyle: pw.BorderStyle.dashed),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('ÖDEME DETAYLARI', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.indigo)),
                pw.SizedBox(height: 4),
                pw.Text('Ödeme Yöntemi: $odemeTuru', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Ödenen Tutar: ${_currencyFormat.format(odenenTutar)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            if (!isGenericCari)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('CARİ HESAP DURUMU', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.indigo)),
                  pw.SizedBox(height: 4),
                  if (kalanBorc > 0)
                    pw.Text('Bu İşlemden Kalan Borç: ${_currencyFormat.format(kalanBorc)}', style: pw.TextStyle(fontSize: 11, color: PdfColors.red)),
                  pw.SizedBox(height: 4),
                  _buildBalanceText(cari.bakiye),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildBalanceText(double bakiye) {
    String label = '';
    PdfColor color = PdfColors.black;
    
    if (bakiye > 0) {
      label = 'Müşteri Borcu (Alınacak):';
      color = PdfColors.red;
    } else if (bakiye < 0) {
      label = 'Firma Alacağı (Ödenecek):';
      color = PdfColors.green;
    } else {
      label = 'Cari Hesap Bakiyesi:';
    }

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label ', style: const pw.TextStyle(fontSize: 11)),
        pw.Text(_currencyFormat.format(bakiye.abs()), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, double value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: isBold ? 14 : 12)),
          pw.Text(_currencyFormat.format(value), style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: isBold ? 14 : 12)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(String kasiyer) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('İşlemi Yapan: $kasiyer', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text('Bizi tercih ettiğiniz için teşekkür ederiz.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text('Hesapix - Akıllı ERP Çözümleri', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
      ],
    );
  }

  // Yazdırma ve Paylaşma İşlemleri
  static Future<void> printPdf(Uint8List pdfData, String jobName) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: jobName,
    );
  }

  static Future<void> sharePdf(Uint8List pdfData, String filename) async {
    await Printing.sharePdf(bytes: pdfData, filename: '$filename.pdf');
  }
}
