import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hesapix_app/models/auth_user.dart';

class AuthService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  AuthService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<AuthUser> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final email = usernameOrEmail.trim().toLowerCase();
    final parola = password;

    if (email.isEmpty || parola.isEmpty) {
      throw AuthException('E-posta ve şifre zorunlu.');
    }

    UserCredential cred;
    try {
      cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: parola,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    }

    if (cred.user == null) {
      throw AuthException('Giriş başarısız. Tekrar deneyin.');
    }

    final userSnap = await _db
        .collection('kullanicilar')
        .where('email', isEqualTo: email)
        .get();

    if (userSnap.docs.isNotEmpty) {
      final docs = userSnap.docs;
      final adminDoc = docs.where((d) {
        final rol = _normalizeRole(_readRoleValue(d.data()));
        return rol == 'admin';
      });
      final doc = adminDoc.isNotEmpty ? adminDoc.first : docs.first;
      final data = doc.data();
      final aktif = (data['aktif'] ?? true) as bool;
      if (!aktif) {
        throw AuthException('Bu kullanıcı pasif. Lütfen yöneticiye başvurun.');
      }

      final roleRaw = _normalizeRole(_readRoleValue(data));
      final role = roleRaw == 'admin' ? 'Admin' : 'Kasiyer';
      final displayName = (data['ad_soyad'] ?? email).toString();
      await _db
          .collection('kullanicilar')
          .doc(doc.id)
          .update({
        'son_giris_tarihi': FieldValue.serverTimestamp(),
        'son_giriş_tarihi': FieldValue.serverTimestamp(),
      });

      return AuthUser(id: doc.id, username: displayName, role: role);
    }

    await _auth.signOut();
    throw AuthException(
      'Giriş başarılı ama kullanıcı profili bulunamadı. "kullanicilar" koleksiyonuna bu e-postayı ekleyin.',
    );
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı';
      case 'invalid-email':
        return 'E-posta formatı geçersiz';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Daha sonra tekrar deneyin.';
      default:
        return 'Giriş sırasında bir hata oluştu';
    }
  }

  String _normalizeRole(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll(' ', '');
  }

  String _readRoleValue(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      final key = entry.key
          .trim()
          .toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll('İ', 'i')
          .replaceAll(' ', '');
      if (key == 'rol') {
        return (entry.value ?? '').toString();
      }
    }
    return 'Kasiyer';
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

