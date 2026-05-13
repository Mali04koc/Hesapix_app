import 'package:hesapix_app/models/auth_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _kIsRemembered = 'session_is_remembered';
  static const _kUserId = 'session_user_id';
  static const _kUsername = 'session_username';
  static const _kRole = 'session_role';

  static const _kLastUserEmail = 'session_last_user_email';
  static const _kLastUserName = 'session_last_user_name';

  Future<void> save(AuthUser user, {required bool rememberMe}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsRemembered, rememberMe);

    // Her durumda son giren kullanıcıyı hatırla (Identity memory)
    await prefs.setString(_kLastUserEmail, user.username); // Burada username email olabilir
    await prefs.setString(_kLastUserName, user.username);

    if (!rememberMe) {
      await clear();
      return;
    }

    await prefs.setString(_kUserId, user.id);
    await prefs.setString(_kUsername, user.username);
    await prefs.setString(_kRole, user.role);
  }

  Future<Map<String, String>?> getLastUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kLastUserEmail);
    final name = prefs.getString(_kLastUserName);
    if (email == null) return null;
    return {'email': email, 'name': name ?? email};
  }

  Future<void> forgetLastUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastUserEmail);
    await prefs.remove(_kLastUserName);
  }

  Future<AuthUser?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool(_kIsRemembered) ?? false;
    if (!remembered) return null;

    final id = prefs.getString(_kUserId);
    final username = prefs.getString(_kUsername);
    final role = prefs.getString(_kRole);
    if (id == null || username == null || role == null) return null;

    return AuthUser(id: id, username: username, role: role);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIsRemembered);
    await prefs.remove(_kUserId);
    await prefs.remove(_kUsername);
    await prefs.remove(_kRole);
  }
}

