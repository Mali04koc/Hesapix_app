import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_test_setup.dart';

/// Widget testleri için Firebase + SharedPreferences hazırlığı.
Future<void> initWidgetTests() async {
  SharedPreferences.setMockInitialValues({});
  await initFirebaseForTests();
}

Future<void> pumpApp(
  WidgetTester tester,
  Widget home, {
  List<SingleChildWidget>? providers,
}) async {
  Widget child = MaterialApp(home: home);
  if (providers != null && providers.isNotEmpty) {
    child = MultiProvider(providers: providers, child: child);
  }
  await tester.pumpWidget(child);
  await tester.pump();
}

/// Firebase stream sayfalarında kısa pump (pumpAndSettle takılmaz).
Future<void> pumpSmokeFrames(WidgetTester tester, {int frames = 3}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
