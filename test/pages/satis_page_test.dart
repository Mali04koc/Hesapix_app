import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/pages/home/admin_home/satis_arayuz/satis_faturasi_detay_page.dart';
import 'package:hesapix_app/models/cari_model.dart';

void main() {
  Widget createWidgetUnderTest(Cari cari) {
    return MaterialApp(
      home: SatisFaturasiDetayPage(cari: cari),
    );
  }

  group('SatisFaturasiDetayPage Widget Testleri', () {
    testWidgets('Gerekli UI bileşenleri ekranda görünmeli', (WidgetTester tester) async {
      final cari = Cari(
        id: 'cari1',
        cariKodu: 'C001',
        firmaAdi: 'Test Firma',
        vergiNo: '1234567890',
        mail: 'test@test.com',
        adres: 'Adres',
        bakiye: 0.0,
      );

      await tester.pumpWidget(createWidgetUnderTest(cari));

      // AppBar title kontrolü
      expect(find.text('Fatura: Test Firma'), findsOneWidget);

      // Arama alanı kontrolü
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Barkod, Ürün Adı veya Kodu (Yazmaya başlayın)'), findsOneWidget);

      // Barkod okuyucu butonu
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);

      // Sepet butonu kontrolü (Badge ile sarmalanmış)
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    });

    testWidgets('Sepet boşken ödeme sayfasına geçiş engellenmeli', (WidgetTester tester) async {
      final cari = Cari(
        id: 'cari1',
        cariKodu: 'C001',
        firmaAdi: 'Test Firma',
        vergiNo: '1234567890',
        mail: 'test@test.com',
        adres: 'Adres',
        bakiye: 0.0,
      );

      await tester.pumpWidget(createWidgetUnderTest(cari));

      // Sepet butonuna tıkla
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pump();

      // Hata mesajını (SnackBar) kontrol et
      expect(find.text('Sepetiniz boş. Lütfen ürün ekleyin.'), findsOneWidget);
    });
  });
}
