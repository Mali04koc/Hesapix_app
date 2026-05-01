import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hesapix_app/app_routes.dart';
import 'package:hesapix_app/firebase_options.dart';
import 'package:hesapix_app/pages/home/admin_home/admin_home_page.dart';
import 'package:hesapix_app/pages/login/forgot_password_page.dart';
import 'package:hesapix_app/pages/home/kasiyer_home/kasiyer_home_page.dart';
import 'package:hesapix_app/pages/home/admin_home/kullanici_yonetimi/kullanici_yonetimi_page.dart';
import 'package:hesapix_app/pages/login/login_page.dart';
import 'package:hesapix_app/pages/module_page.dart';
import 'package:hesapix_app/pages/splash_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hesapix_app/pages/stok_hareket_gecmisi_page.dart';
import 'package:hesapix_app/pages/home/admin_home/stok_yonetimi/stok_yonetimi_page.dart';
import 'package:hesapix_app/pages/home/admin_home/cari_yonetimi/cari_yonetimi_page.dart';
import 'package:hesapix_app/pages/home/admin_home/odeme_islemleri/odeme_islemleri_page.dart';
import 'package:hesapix_app/pages/home/admin_home/fiyat_gor/fiyat_gor_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hesapix App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashPage(),
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.adminHome: (_) => const AdminHomePage(),
        AppRoutes.kasiyerHome: (_) => const KasiyerHomePage(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordPage(),
        AppRoutes.fiyatGor: (_) => const FiyatGorPage(),
        AppRoutes.stokYonetimi: (_) => const StokYonetimiPage(),
        AppRoutes.satisFaturasi: (_) => const ModulePage(title: 'Satış Faturası'),
        AppRoutes.alisFaturasi: (_) => const ModulePage(title: 'Alış Faturası'),
        AppRoutes.cariHesapYonetimi: (_) => const CariYonetimiPage(),
        AppRoutes.raporlar: (_) => const ModulePage(title: 'Raporlar'),
        AppRoutes.kullaniciYonetimi: (_) => const KullaniciYonetimiPage(),
        AppRoutes.finansYonetimi: (_) =>
            const ModulePage(title: 'Finans Yönetimi'),
        AppRoutes.stokHareketGecmisi: (_) => const StokHareketGecmisiPage(),
        AppRoutes.odemeIslemleri: (_) => const OdemeIslemleriPage(),
      },
    );
  }
}
