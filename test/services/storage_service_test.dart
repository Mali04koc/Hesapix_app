import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/services/storage_service.dart';

void main() {
  group('StorageService Testleri', () {
    late StorageService storageService;

    setUp(() {
      storageService = StorageService();
    });

    test('ensureFileExists() dosya yoksa hata fırlatmalı', () {
      final missing = File(r'C:\nonexistent\hesapix_test_image.jpg');

      expect(
        () => storageService.ensureFileExists(missing),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Dosya bulunamadı'),
          ),
        ),
      );
    });

    test('uploadImage() dosya yoksa Firebase çağrılmadan hata vermeli', () async {
      final missing = File(r'C:\nonexistent\hesapix_upload_test.jpg');

      expect(
        () => storageService.uploadImage(missing, 'urunler'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Dosya bulunamadı'),
          ),
        ),
      );
    });

    test('uploadImage() geçerli dosyada klasör yolunu kullanmalı', () async {
      final tempDir = await Directory.systemTemp.createTemp('hesapix_storage_test');
      final tempFile = File('${tempDir.path}/test.jpg');
      await tempFile.writeAsBytes([0xFF, 0xD8, 0xFF]);

      try {
        await storageService.uploadImage(tempFile, 'urunler');
        fail('Firebase Storage bağlantısı olmadan başarılı olmamalı');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), isNot(contains('Dosya bulunamadı')));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
