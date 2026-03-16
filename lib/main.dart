import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hesapix_app/firebase_options.dart';
import 'package:hesapix_app/models/kasiyer_model.dart';
import 'package:hesapix_app/services/firestore_service.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Hesapix Uygulaması - Firebase Hazır!'),
        ),
      ),
    );
  }
}
