import 'package:hesapix_app/models/auth_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _kIsRemembered = 'session_is_remembered';
  static const _kUserId = 'session_user_id';
  static const _kUsername = 'session_username';
  static const _kRole = 'session_role';

  Future<void> save(AuthUser user, {required bool rememberMe}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsRemembered, rememberMe);

    if (!rememberMe) {
      await clear();
      return;
    }

    await prefs.setString(_kUserId, user.id);
    await prefs.setString(_kUsername, user.username);
    await prefs.setString(_kRole, user.role);
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

