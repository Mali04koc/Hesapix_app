import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

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
        maxPageWidth: 700,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        actions: [
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
