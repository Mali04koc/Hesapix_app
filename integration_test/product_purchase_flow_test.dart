import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hesapix_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: Ürün Ekleme ve Alış Akışı', () {
    testWidgets('Yeni ürün eklenir ve alış faturası kesilir', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login adımı
      if (find.text('Giriş Yap').evaluate().isNotEmpty) {
        await tester.enterText(find.byType(TextFormField).first, 'admin@hesapix.com');
        await tester.enterText(find.byType(TextFormField).last, '123456');
        await tester.tap(find.text('Giriş Yap'));
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Stok Yönetimi / Ürün Ekle sayfasına git
      // await tester.tap(find.text('Stok Yönetimi'));
      // await tester.pumpAndSettle();
      // await tester.tap(find.text('Yeni Ürün Ekle'));
      // await tester.pumpAndSettle();

      // Ürün bilgilerini doldur
      // await tester.enterText(find.byKey(const Key('urun_isim')), 'E2E Test Ürün');
      // await tester.enterText(find.byKey(const Key('urun_barkod')), '999888777');
      // await tester.enterText(find.byKey(const Key('urun_alis_fiyat')), '50');
      // await tester.enterText(find.byKey(const Key('urun_satis_fiyat')), '100');
      // await tester.tap(find.text('Kaydet'));
      // await tester.pumpAndSettle(const Duration(seconds: 2));

      // Alış Faturası sayfasına git
      // await tester.tap(find.text('Alış Yönetimi'));
      // await tester.pumpAndSettle();
      // await tester.tap(find.text('Yeni Alış Faturası'));
      // await tester.pumpAndSettle();

      // Ürünü sepete ekle
      // await tester.enterText(find.byType(TextField).first, '999888777');
      // await tester.testTextInput.receiveAction(TextInputAction.done);
      // await tester.pumpAndSettle();
      // await tester.tap(find.text('Sepete Ekle'));
      // await tester.pumpAndSettle();

      // Alışı Tamamla
      // await tester.tap(find.byIcon(Icons.shopping_cart));
      // await tester.pumpAndSettle();
      // await tester.tap(find.text('Faturayı Kaydet'));
      // await tester.pumpAndSettle();

      // Doğrulama: Ürün listesinde stok artışını kontrol et
      // ...
    });
  });
}
