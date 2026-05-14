import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/pages/home/admin_home/alis_yonetimi/alis_page.dart';
import 'package:provider/provider.dart';
import 'package:hesapix_app/services/alis_provider.dart';

void main() {
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

      // Sayfa yüklenirken genel başlık veya bar olması beklenir.
      // İçerisinde "Alış" kelimesi geçen temel appbar/başlık test edilir.
      expect(find.textContaining('Alış'), findsWidgets);
    });
  });
}
