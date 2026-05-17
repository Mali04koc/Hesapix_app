import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/pages/login/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/firebase_test_setup.dart';

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Firebase.initializeApp();
  });

  
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: LoginPage(),
    );
  }

  group('LoginPage Widget Testleri', () {
    testWidgets('Gerekli UI bileşenleri ekranda görünmeli', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // HESAPIX yazısı kontrolü
      expect(find.text('HESA'), findsOneWidget);
      expect(find.text('PIX'), findsOneWidget);
      expect(find.text('Ticari Yönetim ve Faturalama Sistemi'), findsOneWidget);

      // Email ve Şifre alanları kontrolü
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('E-posta'), findsOneWidget);
      expect(find.text('Şifre'), findsOneWidget);

      // Beni hatırla checkbox'ı
      expect(find.text('Beni hatırla'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      // Şifremi unuttum butonu
      expect(find.text('Şifremi unuttum'), findsOneWidget);

      // Giriş yap butonu
      expect(find.text('Giriş Yap'), findsOneWidget);
    });

    testWidgets('Boş alanlarla giriş yapılmaya çalışıldığında hata vermeli', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Giriş butonuna tıkla
      await tester.tap(find.text('Giriş Yap'));
      await tester.pump();

      // Hata mesajlarını kontrol et
      expect(find.text('Bu alan zorunlu'), findsOneWidget); // Email için
      expect(find.text('Şifre zorunlu'), findsOneWidget); // Şifre için
    });

    testWidgets('Şifre görünürlüğü butonu çalışmalı', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Şifre alanını bul (2. TextFormField)
      final passwordField = find.byType(TextFormField).last;
      
      // Başlangıçta şifre gizli olmalı (obscureText = true)
      TextField textFieldWidget = tester.widget<TextField>(find.descendant(of: passwordField, matching: find.byType(TextField)));
      expect(textFieldWidget.obscureText, true);

      // Görünürlük ikonunu bul ve tıkla (Icons.visibility_outlined veya Icons.visibility_off_outlined)
      final visibilityIcon = find.byIcon(Icons.visibility_off_outlined);
      expect(visibilityIcon, findsOneWidget);
      
      await tester.tap(visibilityIcon);
      await tester.pump();

      // Şimdi şifre görünür olmalı
      textFieldWidget = tester.widget<TextField>(find.descendant(of: passwordField, matching: find.byType(TextField)));
      expect(textFieldWidget.obscureText, false);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('E-posta girilip, şifre boşken sadece şifre hatası vermeli', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Email alanına metin gir
      await tester.enterText(find.byType(TextFormField).first, 'test@test.com');
      
      // Giriş butonuna tıkla
      await tester.tap(find.text('Giriş Yap'));
      await tester.pump();

      // Hata mesajlarını kontrol et
      expect(find.text('Bu alan zorunlu'), findsNothing); // Email hatası olmamalı
      expect(find.text('Şifre zorunlu'), findsOneWidget); // Şifre hatası olmalı
    });
  });
}
