import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/pages/home/admin_home/pdf/pdf_preview_page.dart';
import 'package:printing/printing.dart';

import '../helpers/widget_test_harness.dart';

void main() {
  setUpAll(() async {
    await initWidgetTests();
  });

  group('PdfPreviewPage', () {
    testWidgets('başlık ve önizleme alanı yüklenir', (tester) async {
      // Minimal geçerli PDF içeriği
      const minimalPdf = '%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF';
      final bytes = Uint8List.fromList(minimalPdf.codeUnits);

      await pumpApp(
        tester,
        PdfPreviewPage(
          pdfData: bytes,
          title: 'Test Fatura',
          filename: 'test_fatura',
        ),
      );

      expect(find.text('Test Fatura'), findsOneWidget);
      expect(find.byType(PdfPreview), findsOneWidget);
    });
  });
}
