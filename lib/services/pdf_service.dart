import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:hesapix_app/models/satis_model.dart';
import 'package:hesapix_app/models/satis_detay_model.dart';
import 'package:hesapix_app/models/alis_model.dart';
import 'package:hesapix_app/models/alis_detay_model.dart';

class PdfService {
  static final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  static final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  // Satış Faturası (PDF) Oluştur
  static Future<Uint8List> generateSatisFaturasiPdf({
    required Satis satis,
    required List<SatisDetay> detaylar,
    required String cariIsim,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('SATIŞ FATURASI', satis.faturaNo, satis.tarih),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(cariIsim, 'Müşteri Bilgileri'),
              pw.SizedBox(height: 20),
              _buildSatisItemsTable(detaylar),
              pw.SizedBox(height: 20),
              _buildTotals(satis.araToplam, satis.iskonto, satis.kdvToplam, satis.genelToplam, satis.odemeTuru),
              pw.SizedBox(height: 40),
              _buildFooter(),
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
    required String tedarikciIsim,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('ALIŞ FATURASI', alis.faturaNo, alis.tarih),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(tedarikciIsim, 'Tedarikçi Bilgileri'),
              pw.SizedBox(height: 20),
              _buildAlisItemsTable(detaylar),
              pw.SizedBox(height: 20),
              _buildTotals(alis.araToplam, alis.iskonto, alis.kdvToplam, alis.genelToplam, alis.odemeTuru),
              pw.SizedBox(height: 40),
              _buildFooter(),
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
            pw.Text('HESAPİX ERP', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
            pw.Text('Profesyonel Ön Muhasebe Çözümü', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
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
  static pw.Widget _buildCustomerInfo(String isim, String baslik) {
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
          pw.Text(isim, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
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
  static pw.Widget _buildTotals(double araToplam, double iskonto, double kdv, double genelToplam, String odemeTuru) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Ödeme Türü:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(odemeTuru, style: const pw.TextStyle(fontSize: 16)),
          ],
        ),
        pw.Container(
          width: 250,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
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

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Text('Bizi tercih ettiğiniz için teşekkür ederiz.', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.Text('Hesapix - Akıllı ERP Çözümleri', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
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
