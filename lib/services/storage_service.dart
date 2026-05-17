import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage? _injectedStorage;

  StorageService({FirebaseStorage? storage}) : _injectedStorage = storage;

  FirebaseStorage get _storage =>
      _injectedStorage ?? FirebaseStorage.instance;

  /// Yüklemeden önce dosya varlığını doğrular (test ve hata mesajları için ayrık).
  void ensureFileExists(File file) {
    if (!file.existsSync()) {
      throw Exception('Dosya bulunamadı: ${file.path}');
    }
  }

  Future<String?> uploadImage(File file, String folder) async {
    try {
      ensureFileExists(file);

      final String basename = file.path.split('/').last.split('\\').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$basename';
      final ref = _storage.ref().child('$folder/$fileName');

      final snapshot = await ref.putFile(file);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
