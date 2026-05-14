import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/pages/home/admin_home/raporlar/tahsilat_raporlari_page.dart';

void main() {
  group('TahsilatRaporlariPage Widget Testleri', () {
    testWidgets('Sayfa temel UI elemanlarını içermeli', (WidgetTester tester) async {
      // Not: Bu sayfa initState içinde doğrudan _raporService'i çağırdığından
      // test ortamında Firebase başlatılmamışsa hata verebilir.
      // Projede Dependency Injection (Provider/GetIt) kullanılmadığı için
      // basit bir render testi yapıyoruz.
      
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: TahsilatRaporlariPage(),
        ),
      ));

      // CircularProgressIndicator görünüyor olmalı (çünkü _isLoading = true başlıyor)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // AppBar başlıkları kontrolü
      expect(find.text('Tahsilat & Borç Raporları'), findsOneWidget);
      expect(find.text('Tahsilatlar'), findsOneWidget);
      expect(find.text('Açık Borçlar'), findsOneWidget);
    });
  });
}
