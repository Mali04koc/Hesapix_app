import 'package:flutter/material.dart';
import 'package:hesapix_app/app_routes.dart';
import 'package:hesapix_app/services/auth_service.dart';
import 'package:hesapix_app/services/session_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Referans tasarıma yakın: açık arka plan, lacivert–turuncu marka, turuncu gradient giriş.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _navy = Color(0xFF004080);
  static const _orange = Color(0xFFFF8C00);
  static const _orangeDeep = Color(0xFFE67E00);
  static const _bg = Color(0xFFF8F9FA);
  static const _border = Color(0xFFD1D1D1);
  static const _textMuted = Color(0xFF5C5C5C);

  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();

  bool _rememberMe = true;
  bool _obscure = true;
  bool _loading = false;
  Map<String, String>? _lastUser; // Son giren kullanıcı bilgisi

  @override
  void initState() {
    super.initState();
    _checkLastUser();
  }

  Future<void> _checkLastUser() async {
    final last = await SessionService().getLastUser();
    if (last != null) {
      setState(() {
        _lastUser = last;
        _usernameCtrl.text = last['email'] ?? '';
      });
    }
  }

  Future<void> _biometricLogin() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        _snack('Cihazınızda biyometrik giriş desteklenmiyor.');
        return;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Giriş yapmak için lütfen parmak izinizi okutun',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );

      if (didAuthenticate) {
        // Kayıtlı şifreyi getir (Email'i anahtar olarak kullanıyoruz)
        final email = _usernameCtrl.text.trim().toLowerCase();
        final savedPassword = await _secureStorage.read(key: 'user_password_$email');
        if (savedPassword != null) {
          _passwordCtrl.text = savedPassword;
          _submit(isBiometric: true);
        } else {
          _snack('Biyometrik giriş için önce şifrenizle normal bir giriş yapmalısınız (Beni Hatırla seçili iken).');
        }
      }
    } catch (e) {
      _snack('Biyometrik giriş sırasında bir hata oluştu.');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit({bool isBiometric = false}) async {
    FocusScope.of(context).unfocus();
    if (!isBiometric && !_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final user = await AuthService().login(
        usernameOrEmail: _usernameCtrl.text,
        password: _passwordCtrl.text,
      );

      await SessionService().save(user, rememberMe: _rememberMe);
      
      // Şifreyi güvenli depolamaya kaydet (Email anahtarı ile)
      if (_rememberMe) {
        final email = user.email.trim().toLowerCase();
        await _secureStorage.write(key: 'user_password_$email', value: _passwordCtrl.text);
      }

      if (!mounted) return;

      final normalizedRole = user.role
          .trim()
          .toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll('İ', 'i')
          .replaceAll(' ', '');
      final route = normalizedRole == 'admin'
          ? AppRoutes.adminHome
          : AppRoutes.kasiyerHome;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(e.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Bir hata oluştu. Lütfen tekrar dene.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    _buildLogoTile(),
                    const SizedBox(height: 22),
                    _buildBrandTitle(theme),
                    const SizedBox(height: 8),
                    Text(
                      'Ticari Yönetim ve Faturalama Sistemi',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _textMuted,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 36),
                    if (_lastUser != null) ...[
                      // Trust Wallet tarzı kullanıcı başlığı
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: _navy.withOpacity(0.1),
                              child: const Icon(Icons.person, size: 50, color: _navy),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Hoş geldin,',
                              style: theme.textTheme.bodyMedium?.copyWith(color: _textMuted),
                            ),
                            Text(
                              _lastUser!['name']!,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: _navy),
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                _lastUser = null;
                                _usernameCtrl.clear();
                              }),
                              child: const Text('Başka hesapla giriş yap', style: TextStyle(color: _orange)),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      TextFormField(
                        controller: _usernameCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'E-posta',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: _navy, width: 1.4),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red.shade300),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Bu alan zorunlu';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordCtrl,
                      textInputAction: TextInputAction.done,
                      obscureText: _obscure,
                      onFieldSubmitted: (_) => _submit(),
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Şifre',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.grey.shade600,
                          size: 22,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _navy, width: 1.4),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red.shade300),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Şifre zorunlu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: _loading
                                ? null
                                : (v) =>
                                    setState(() => _rememberMe = v ?? true),
                            activeColor: _navy,
                            side: const BorderSide(color: _border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Beni hatırla',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.of(context)
                                  .pushNamed(AppRoutes.forgotPassword),
                          style: TextButton.styleFrom(
                            foregroundColor: _navy,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Şifremi unuttum'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _OrangeGradientButton(
                            loading: _loading,
                            onTap: _loading ? null : _submit,
                          ),
                        ),
                        if (_lastUser != null) ...[
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: _biometricLogin,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                border: Border.all(color: _navy.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: const Icon(Icons.fingerprint, color: _navy, size: 30),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoTile() {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF003366),
              Color(0xFF004080),
              Color(0xFF005C99),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            'assets/images/app_logo.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildBrandTitle(ThemeData theme) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'HESA',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: _navy,
              fontSize: 34,
            ),
          ),
          Text(
            'PIX',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: _orange,
              fontSize: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrangeGradientButton extends StatelessWidget {
  const _OrangeGradientButton({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: disabled
                ? LinearGradient(
                    colors: [
                      Colors.grey.shade400,
                      Colors.grey.shade500,
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFAB40),
                      _LoginPageState._orange,
                      _LoginPageState._orangeDeep,
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Giriş Yap',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
