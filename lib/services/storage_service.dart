import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage(File file, String folder) async {
    try {
      final String basename = file.path.split('/').last.split('\\').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$basename';
      final ref = _storage.ref().child('$folder/$fileName');
      
      print('Yükleme başlatılıyor: ${file.path}');
      if (!file.existsSync()) {
        throw Exception('Dosya bulunamadı: ${file.path}');
      }
      final snapshot = await ref.putFile(file);
      print('Yükleme tamamlandı, URL alınıyor...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('URL alındı: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Resim yükleme hatası: $e');
      throw Exception(e.toString());
    }
  }
}
