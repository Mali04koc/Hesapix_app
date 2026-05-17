import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/pages/home/admin_home/kullanici_yonetimi/dialogs/confirm_dialog.dart';

void main() {
  group('ConfirmDialog', () {
    testWidgets('başlık, mesaj ve butonları gösterir', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<bool>(
                      context: context,
                      builder: (_) => const ConfirmDialog(
                        title: 'Silinsin mi?',
                        message: 'Bu işlem geri alınamaz.',
                        confirmLabel: 'Sil',
                        isDestructive: true,
                      ),
                    );
                  },
                  child: const Text('Aç'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      expect(find.text('Silinsin mi?'), findsOneWidget);
      expect(find.text('Bu işlem geri alınamaz.'), findsOneWidget);
      expect(find.text('İptal'), findsOneWidget);
      expect(find.text('Sil'), findsOneWidget);

      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('İptal false döndürür', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) => const ConfirmDialog(
                      title: 'Onay',
                      message: 'Devam?',
                      confirmLabel: 'Evet',
                    ),
                  );
                },
                child: const Text('Aç'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
