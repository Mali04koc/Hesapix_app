import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesapix_app/utils/firestore_user_fields.dart';

class AppUserModel {
  /// Firestore doküman kimliği (çoğunlukla Firebase Auth UID ile aynı).
  final String id;
  /// Firebase Authentication kullanıcı UID (varsa).
  final String uid;
  final String adSoyad;
  final String email;
  final String rol; // Admin | Kasiyer
  final bool aktif;
  final DateTime? sonGirisTarihi;
  final DateTime olusturulmaTarihi;

  const AppUserModel({
    required this.id,
    required this.uid,
    required this.adSoyad,
    required this.email,
    required this.rol,
    required this.aktif,
    required this.sonGirisTarihi,
    required this.olusturulmaTarihi,
  });

  factory AppUserModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final uidStr = (data['uid'] ?? doc.id).toString();
    return AppUserModel(
      id: doc.id,
      uid: uidStr,
      adSoyad: (data['ad_soyad'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      rol: readRoleFromData(data),
      aktif: (data['aktif'] ?? true) as bool,
      sonGirisTarihi:
          _tsToDate(data['son_giris_tarihi'] ?? data['son_giriş_tarihi']),
      olusturulmaTarihi:
          _tsToDate(data['olusturulma_tarihi'] ?? data['oluşturulma_tarihi']) ??
              DateTime.now(),
    );
  }

  static DateTime? _tsToDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
