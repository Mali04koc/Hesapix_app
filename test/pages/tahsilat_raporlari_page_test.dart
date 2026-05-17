import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/pages/home/admin_home/raporlar/tahsilat_raporlari_page.dart';

import '../helpers/firebase_test_setup.dart';

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('TahsilatRaporlariPage Widget Testleri', () {
    testWidgets('Sayfa temel UI elemanlarını içermeli', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: TahsilatRaporlariPage(),
        ),
      ));
      await tester.pump();

      // CircularProgressIndicator görünüyor olmalı (çünkü _isLoading = true başlıyor)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // AppBar başlıkları kontrolü
      expect(find.text('Tahsilat & Borç Raporları'), findsOneWidget);
      expect(find.text('Tahsilatlar'), findsOneWidget);
      expect(find.text('Açık Borçlar'), findsOneWidget);
    });
  });
}
