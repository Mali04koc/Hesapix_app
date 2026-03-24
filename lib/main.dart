import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hesapix_app/app_routes.dart';
import 'package:hesapix_app/firebase_options.dart';
import 'package:hesapix_app/pages/admin_home_page.dart';
import 'package:hesapix_app/pages/forgot_password_page.dart';
import 'package:hesapix_app/pages/kasiyer_home_page.dart';
import 'package:hesapix_app/pages/login_page.dart';
import 'package:hesapix_app/pages/splash_page.dart';

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
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashPage(),
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.adminHome: (_) => const AdminHomePage(),
        AppRoutes.kasiyerHome: (_) => const KasiyerHomePage(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordPage(),
      },
    );
  }
}
