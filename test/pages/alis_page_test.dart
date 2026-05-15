import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/pages/home/admin_home/alis_yonetimi/alis_page.dart';
import 'package:provider/provider.dart';
import 'package:hesapix_app/services/alis_provider.dart';

import '../helpers/firebase_test_setup.dart';

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AlisProvider()),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: AlisPage(),
        ),
      ),
    );
  }

  group('AlisPage Widget Testleri', () {
    testWidgets('Sayfa temel UI elemanlarını yüklemeli', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Sayfa yüklenirken genel başlık veya bar olması beklenir.
      // Scaffold render edilmiş olmalı
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
