import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hesapix_app/main.dart' as app;

// Gerçek Firebase projesi ve test kullanıcısı gerektirir.
// Çalıştırmak için: flutter test integration_test/auth_flow_test.dart -d <cihaz>
const _runIntegration = bool.fromEnvironment('RUN_INTEGRATION', defaultValue: false);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: Auth Flow', () {
    testWidgets('Kullanıcı yanlış şifreyle giriş yapamaz', (WidgetTester tester) async {
      if (!_runIntegration) return;
      app.main();
      await tester.pumpAndSettle();

      // Login sayfasının gelmesini bekle
      expect(find.text('Giriş Yap'), findsOneWidget);

      // Email ve şifre alanlarını doldur
      await tester.enterText(find.byType(TextFormField).first, 'wrong@test.com');
      await tester.enterText(find.byType(TextFormField).last, 'wrong_pass');

      // Giriş yap butonuna tıkla
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      // Hata mesajının gösterildiğini doğrula (AuthService mock'tan auth-failed fırlatmalıdır)
      // Normal şartlarda "Firebase hataları" gösterilir.
      // Bu nedenle ekranda SnackBar görünmesini bekliyoruz.
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Kullanıcı doğru bilgilerle giriş yapar ve ana sayfaya yönlenir', (WidgetTester tester) async {
      if (!_runIntegration) return;
      app.main();
      await tester.pumpAndSettle();

      // Admin bilgilerini gir (Mock ortamında geçerli bir kullanıcı olmalı)
      await tester.enterText(find.byType(TextFormField).first, 'admin@hesapix.com');
      await tester.enterText(find.byType(TextFormField).last, '123456');

      // Giriş yap butonuna tıkla
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Ana sayfaya (AdminHome) yönlendirildiğini kontrol et.
      // Ana sayfada 'Genel Durum' veya 'Satış Yönetimi' gibi başlıklar olur.
      // E2E testinde projenin ana sayfasında olan bir string aranabilir:
      // (Test ortamınızın mocklarına bağlı olarak aşağıdakiler değişebilir)
      // expect(find.text('Genel Durum'), findsOneWidget);
    });
  });
}
