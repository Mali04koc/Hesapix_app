import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/app_routes.dart';
import 'package:hesapix_app/pages/home/admin_home/admin_home_page.dart';
import 'package:hesapix_app/pages/home/admin_home/alis_yonetimi/alis_page.dart';
import 'package:hesapix_app/pages/home/admin_home/cari_yonetimi/cari_yonetimi_page.dart';
import 'package:hesapix_app/pages/home/admin_home/fiyat_gor/fiyat_gor_page.dart';
import 'package:hesapix_app/pages/home/admin_home/kullanici_yonetimi/kullanici_yonetimi_page.dart';
import 'package:hesapix_app/pages/home/admin_home/odeme_islemleri/odeme_islemleri_page.dart';
import 'package:hesapix_app/pages/home/admin_home/raporlar/alis_raporlari_page.dart';
import 'package:hesapix_app/pages/home/admin_home/raporlar/cari_raporlari_page.dart';
import 'package:hesapix_app/pages/home/admin_home/raporlar/karlilik_raporlari_page.dart';
import 'package:hesapix_app/pages/home/admin_home/raporlar/kullanici_raporlari_page.dart';
import 'package:hesapix_app/pages/home/admin_home/raporlar/raporlar_dashboard_page.dart';
import 'package:hesapix_app/pages/home/admin_home/raporlar/satis_raporlari_page.dart';
import 'package:hesapix_app/pages/home/admin_home/raporlar/stok_raporlari_page.dart';
import 'package:hesapix_app/pages/home/admin_home/raporlar/tahsilat_raporlari_page.dart';
import 'package:hesapix_app/pages/home/admin_home/raporlar/trend_raporlari_page.dart';
import 'package:hesapix_app/pages/home/admin_home/satis_arayuz/satis_faturasi_cari_secim_page.dart';
import 'package:hesapix_app/pages/home/admin_home/stok_yonetimi/stok_yonetimi_page.dart';
import 'package:hesapix_app/pages/home/kasiyer_home/kasiyer_home_page.dart';
import 'package:hesapix_app/pages/login/forgot_password_page.dart';
import 'package:hesapix_app/pages/module_page.dart';
import 'package:hesapix_app/pages/splash_page.dart';
import 'package:hesapix_app/services/alis_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/widget_test_harness.dart';

void main() {
  setUpAll(() async {
    await initWidgetTests();
  });

  group('Sayfa smoke testleri', () {
    for (final entry in _smokeCases) {
      testWidgets('${entry.name} temel UI yüklenir', (tester) async {
        if (entry.name == 'KullaniciYonetimiPage') {
          // FutureBuilder hasData=false when oturum null; admin oturumu ile başlık görünür
          SharedPreferences.setMockInitialValues({
            'session_is_remembered': true,
            'session_user_id': 'admin1',
            'session_username': 'Admin',
            'session_role': 'Admin',
            'session_last_user_email': 'admin@test.com',
          });
        }
        await pumpApp(tester, entry.builder(), providers: entry.providers);
        await pumpSmokeFrames(tester, frames: entry.name == 'KullaniciYonetimiPage' ? 8 : 3);
        final matched = entry.expectedTexts.any(
          (t) => find.text(t).evaluate().isNotEmpty,
        );
        expect(matched, isTrue, reason: 'Beklenen metinlerden biri görünmeli: ${entry.expectedTexts}');
      });
    }
  });

  group('SplashPage', () {
    testWidgets('yüklenirken logo ve progress gösterir', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (_) => const SplashPage(),
            AppRoutes.login: (_) => const Scaffold(body: Text('Login Hedef')),
            AppRoutes.adminHome: (_) => const Scaffold(body: Text('Admin Hedef')),
            AppRoutes.kasiyerHome: (_) => const Scaffold(body: Text('Kasiyer Hedef')),
          },
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}

class _SmokeCase {
  const _SmokeCase({
    required this.name,
    required this.builder,
    required this.expectedTexts,
    this.providers,
  });

  final String name;
  final Widget Function() builder;
  final List<String> expectedTexts;
  final List<SingleChildWidget>? providers;
}

final _smokeCases = <_SmokeCase>[
  _SmokeCase(
    name: 'AdminHomePage',
    builder: () => const AdminHomePage(),
    expectedTexts: ['Hesapix Admin'],
  ),
  _SmokeCase(
    name: 'KasiyerHomePage',
    builder: () => const KasiyerHomePage(),
    expectedTexts: ['Kasiyer Panel'],
  ),
  _SmokeCase(
    name: 'ForgotPasswordPage',
    builder: () => const ForgotPasswordPage(),
    expectedTexts: ['Şifremi Unuttum'],
  ),
  _SmokeCase(
    name: 'ModulePage',
    builder: () => const ModulePage(title: 'Test Modül'),
    expectedTexts: ['Test Modül'],
  ),
  _SmokeCase(
    name: 'CariYonetimiPage',
    builder: () => const CariYonetimiPage(),
    expectedTexts: ['Cari Yönetimi'],
  ),
  _SmokeCase(
    name: 'StokYonetimiPage',
    builder: () => const StokYonetimiPage(),
    expectedTexts: ['Stok Yönetimi'],
  ),
  _SmokeCase(
    name: 'FiyatGorPage',
    builder: () => const FiyatGorPage(),
    expectedTexts: ['Fiyat Gör'],
  ),
  _SmokeCase(
    name: 'OdemeIslemleriPage',
    builder: () => const OdemeIslemleriPage(),
    expectedTexts: ['Ödeme İşlemleri'],
  ),
  _SmokeCase(
    name: 'AlisPage',
    builder: () => const AlisPage(),
    expectedTexts: ['Alış Faturası (Tedarikçi)'],
    providers: [ChangeNotifierProvider(create: (_) => AlisProvider())],
  ),
  _SmokeCase(
    name: 'SatisFaturasiCariSecimPage',
    builder: () => const SatisFaturasiCariSecimPage(),
    expectedTexts: ['Satış Faturası - Cari Seçin'],
  ),
  _SmokeCase(
    name: 'RaporlarDashboardPage',
    builder: () => const RaporlarDashboardPage(),
    expectedTexts: ['Raporlar'],
  ),
  _SmokeCase(
    name: 'SatisRaporlariPage',
    builder: () => const SatisRaporlariPage(),
    expectedTexts: ['Satış Raporları'],
  ),
  _SmokeCase(
    name: 'AlisRaporlariPage',
    builder: () => const AlisRaporlariPage(),
    expectedTexts: ['Alış Raporları'],
  ),
  _SmokeCase(
    name: 'CariRaporlariPage',
    builder: () => const CariRaporlariPage(),
    expectedTexts: ['Cari Hesap Raporları'],
  ),
  _SmokeCase(
    name: 'StokRaporlariPage',
    builder: () => const StokRaporlariPage(),
    expectedTexts: ['Stok Raporları'],
  ),
  _SmokeCase(
    name: 'KarlilikRaporlariPage',
    builder: () => const KarlilikRaporlariPage(),
    expectedTexts: ['Kârlılık Raporları'],
  ),
  _SmokeCase(
    name: 'KullaniciRaporlariPage',
    builder: () => const KullaniciRaporlariPage(),
    expectedTexts: ['Kullanıcı (Personel) Raporları'],
  ),
  _SmokeCase(
    name: 'TahsilatRaporlariPage',
    builder: () => const TahsilatRaporlariPage(),
    expectedTexts: ['Tahsilat & Borç Raporları'],
  ),
  _SmokeCase(
    name: 'TrendRaporlariPage',
    builder: () => const TrendRaporlariPage(),
    expectedTexts: ['Trend Analizi (Son 30 Gün)'],
  ),
  _SmokeCase(
    name: 'KullaniciYonetimiPage',
    builder: () => const KullaniciYonetimiPage(),
    expectedTexts: ['Kullanıcı Yönetimi'],
  ),
];
