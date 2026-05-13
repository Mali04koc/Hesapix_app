import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfPreviewPage extends StatelessWidget {
  final Uint8List pdfData;
  final String title;
  final String filename;

  const PdfPreviewPage({
    super.key,
    required this.pdfData,
    required this.title,
    required this.filename,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: HesapixColors.primary),
      ),
      body: PdfPreview(
        build: (format) => pdfData,
        pdfFileName: "$filename.pdf",
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false, // Kırmızı butonu (debug) kaldırır
        maxPageWidth: 700,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.download_rounded),
            onPressed: (context, build, format) async {
              try {
                // Dosyayı cihazın dökümanlar klasörüne kaydet
                final directory = await getApplicationDocumentsDirectory();
                final file = File('${directory.path}/$filename.pdf');
                await file.writeAsBytes(pdfData);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Dosya kaydedildi: ${file.path}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dosya kaydedilirken bir hata oluştu.')),
                  );
                }
              }
            },
          ),
          PdfPreviewAction(
            icon: const Icon(Icons.share),
            onPressed: (context, build, format) async {
              await Printing.sharePdf(bytes: pdfData, filename: "$filename.pdf");
            },
          ),
        ],
      ),
    );
  }
}
