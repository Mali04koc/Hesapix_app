import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase Core platform mock'larını test ortamında hazırlar.
void setupFirebaseAuthMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
}

/// Widget testleri için Firebase mock + initialize (tek seferlik).
Future<void> initFirebaseForTests() async {
  setupFirebaseAuthMocks();
  await Firebase.initializeApp();
}
