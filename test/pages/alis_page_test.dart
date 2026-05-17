import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/pages/home/admin_home/alis_yonetimi/alis_page.dart';
import 'package:provider/provider.dart';
import 'package:hesapix_app/services/alis_provider.dart';

import '../helpers/widget_test_harness.dart';

void main() {
  setUpAll(() async {
    await initWidgetTests();
  });

  group('AlisPage Widget Testleri', () {
    testWidgets('Sayfa başlığını göstermeli', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const AlisPage(),
        providers: [ChangeNotifierProvider(create: (_) => AlisProvider())],
      );

      expect(find.text('Alış Faturası (Tedarikçi)'), findsOneWidget);
    });
  });
}
