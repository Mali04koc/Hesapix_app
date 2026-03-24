import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/models/auth_user.dart';

class AuthService {
  final FirebaseFirestore _db;

  AuthService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<AuthUser> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final username = usernameOrEmail.trim();
    final parola = password;

    if (username.isEmpty || parola.isEmpty) {
      throw AuthException('Kullanıcı adı ve şifre zorunlu.');
    }

    // 1) Admin kontrolü (koleksiyon: adminler)
    final adminSnap = await _db
        .collection('adminler')
        .where('kullanici_adi', isEqualTo: username)
        .where('parola', isEqualTo: parola)
        .limit(1)
        .get();

    if (adminSnap.docs.isNotEmpty) {
      final doc = adminSnap.docs.first;
      final data = doc.data();
      final uname = (data['kullanici_adi'] ?? username).toString();
      return AuthUser(id: doc.id, username: uname, role: 'Admin');
    }

    // 2) Kasiyer kontrolü (koleksiyon: kasiyerler)
    final kasiyerSnap = await _db
        .collection('kasiyerler')
        .where('kullanici_adi', isEqualTo: username)
        .where('parola', isEqualTo: parola)
        .limit(1)
        .get();

    if (kasiyerSnap.docs.isNotEmpty) {
      final doc = kasiyerSnap.docs.first;
      final data = doc.data();
      final uname = (data['kullanici_adi'] ?? username).toString();
      return AuthUser(id: doc.id, username: uname, role: 'Kasiyer');
    }

    throw AuthException('Kullanıcı adı veya şifre hatalı');
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

