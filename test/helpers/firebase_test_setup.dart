import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase Core platform mock'larını test ortamında hazırlar.
void setupFirebaseAuthMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
}
