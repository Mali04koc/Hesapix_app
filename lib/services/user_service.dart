import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hesapix_app/models/app_user_model.dart';
import 'package:hesapix_app/services/auth_service.dart';
import 'package:hesapix_app/utils/firestore_user_fields.dart';

class UserService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  UserService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('kullanicilar');

  Stream<List<AppUserModel>> streamUsers() {
    return _users
        .orderBy('olusturulma_tarihi', descending: true)
        .snapshots()
        .map((s) => s.docs.map(AppUserModel.fromDoc).toList());
  }

  /// Firebase Auth ile kullanıcı oluşturur, Firestore profilini yazar.
  /// İstemci SDK oturumu yeni kullanıcıya geçtiği için ardından [signOut] çağrılır.
  /// Admin oturumu için tekrar giriş gerekir (Admin SDK / Cloud Function tercih edilir).
  Future<void> createUser({
    required String adSoyad,
    required String email,
    required String password,
    required String rol,
    required bool aktif,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    final existing =
        await _users.where('email', isEqualTo: cleanEmail).limit(1).get();
    if (existing.docs.isNotEmpty) {
      throw AuthException('Bu e-posta ile kullanıcı zaten var.');
    }

    UserCredential? cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    }

    final uid = cred.user?.uid;
    if (uid == null) {
      throw AuthException('Kullanıcı oluşturulamadı.');
    }

    try {
      await _users.doc(uid).set({
        'uid': uid,
        'ad_soyad': adSoyad.trim(),
        'email': cleanEmail,
        'rol': rol,
        'aktif': aktif,
        'son_giris_tarihi': null,
        'olusturulma_tarihi': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await cred.user?.delete();
      rethrow;
    }

    await _auth.signOut();
  }

  Future<void> updateUser({
    required String userId,
    required String adSoyad,
    required String email,
    required String rol,
    required bool aktif,
    required String currentAdminId,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final docRef = _users.doc(userId);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw AuthException('Kullanıcı bulunamadı.');
    }
    final dupQuery =
        await _users.where('email', isEqualTo: cleanEmail).limit(2).get();
    final hasDuplicate = dupQuery.docs.any((d) => d.id != userId);
    if (hasDuplicate) {
      throw AuthException('Bu e-posta başka kullanıcıda kayıtlı.');
    }

    if (userId == currentAdminId && rol != 'Admin') {
      throw AuthException('Kendi rolünü kasiyer yapamazsın.');
    }

    if (rol != 'Admin' || !aktif) {
      await _ensureAnotherAdminExists(excludingUserId: userId);
    }

    await docRef.update({
      'ad_soyad': adSoyad.trim(),
      'email': cleanEmail,
      'rol': rol,
      'aktif': aktif,
    });
  }

  Future<void> deleteUser({
    required String userId,
    required String currentAdminId,
  }) async {
    if (userId == currentAdminId) {
      throw AuthException('Admin kendi hesabını silemez.');
    }

    final doc = await _users.doc(userId).get();
    if (!doc.exists) return;
    final data = doc.data() ?? {};
    final role = readRoleFromData(data);
    final aktif = (data['aktif'] ?? true) as bool;

    if (isAdminRoleValue(role) && aktif) {
      await _ensureAnotherAdminExists(excludingUserId: userId);
    }

    await _users.doc(userId).delete();
  }

  Future<void> setUserActive({
    required String userId,
    required bool aktif,
    required String currentAdminId,
  }) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return;
    final data = doc.data() ?? {};
    final role = readRoleFromData(data);

    if (!aktif && userId == currentAdminId) {
      throw AuthException('Admin kendi hesabını pasife alamaz.');
    }
    if (!aktif && isAdminRoleValue(role)) {
      await _ensureAnotherAdminExists(excludingUserId: userId);
    }

    await _users.doc(userId).update({'aktif': aktif});
  }

  Future<void> _ensureAnotherAdminExists({
    required String excludingUserId,
  }) async {
    final all = await _users.get();
    var count = 0;
    for (final d in all.docs) {
      if (d.id == excludingUserId) continue;
      final data = d.data();
      final rol = readRoleFromData(data);
      final aktif = (data['aktif'] ?? true) as bool;
      if (isAdminRoleValue(rol) && aktif) {
        count++;
      }
    }
    if (count < 1) {
      throw AuthException('Sistemde en az 1 aktif admin kalmalı.');
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta ile Firebase Authentication kaydı zaten var.';
      case 'weak-password':
        return 'Şifre çok zayıf.';
      case 'invalid-email':
        return 'E-posta geçersiz.';
      default:
        return 'Kullanıcı oluşturulamadı.';
    }
  }
}
