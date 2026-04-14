import 'package:flutter/material.dart';
import 'package:hesapix_app/models/app_user_model.dart';
import 'package:hesapix_app/services/auth_service.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/utils/firestore_user_fields.dart';
import 'package:hesapix_app/pages/kullanici_yonetimi/dialogs/confirm_dialog.dart';

class UserDialogResult {
  const UserDialogResult({
    required this.adSoyad,
    required this.email,
    required this.rol,
    required this.aktif,
    this.password,
  });

  final String adSoyad;
  final String email;
  final String rol;
  final bool aktif;
  final String? password;
}

class UserDialog extends StatefulWidget {
  const UserDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSubmit,
    required this.isEdit,
    this.isEditingSelf = false,
    this.existingUser,
  });

  final String title;
  final String subtitle;
  final Future<void> Function(UserDialogResult input) onSubmit;
  final bool isEdit;
  final bool isEditingSelf;
  final AppUserModel? existingUser;

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _adSoyadCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _sifreCtrl;
  late String _initialRol;
  String _rol = 'Kasiyer';
  bool _aktif = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final u = widget.existingUser;
    _adSoyadCtrl = TextEditingController(text: u?.adSoyad ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _sifreCtrl = TextEditingController();
    _rol = u != null
        ? (isAdminRoleValue(u.rol) ? 'Admin' : 'Kasiyer')
        : 'Kasiyer';
    _initialRol = _rol;
    _aktif = u?.aktif ?? true;
  }

  @override
  void dispose() {
    _adSoyadCtrl.dispose();
    _emailCtrl.dispose();
    _sifreCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isEdit &&
        !widget.isEditingSelf &&
        _rol != _initialRol) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => const ConfirmDialog(
          title: 'Rol değişikliği',
          message:
              'Rol değişince kullanıcının menü ve yetkileri anında güncellenir. Devam edilsin mi?',
          confirmLabel: 'Evet, kaydet',
          isDestructive: false,
        ),
      );
      if (ok != true) return;
    }

    setState(() => _loading = true);
    try {
      await widget.onSubmit(
        UserDialogResult(
          adSoyad: _adSoyadCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          rol: _rol,
          aktif: _aktif,
          password: widget.isEdit ? null : _sifreCtrl.text,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: HesapixColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.existingUser;
    final self = widget.isEditingSelf;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: HesapixColors.accentContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.manage_accounts_outlined,
                          color: HesapixColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: HesapixColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: HesapixColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (widget.isEdit && u != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: HesapixColors.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: HesapixColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UID: ${u.uid}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: HesapixColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Oluşturulma: ${_fmtStatic(u.olusturulmaTarihi)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: HesapixColors.textMuted,
                            ),
                          ),
                          Text(
                            'Son giriş: ${_fmtStatic(u.sonGirisTarihi)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: HesapixColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _adSoyadCtrl,
                    decoration: _fieldDeco('Ad Soyad'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: _fieldDeco('E-posta'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Zorunlu alan';
                      if (!v.contains('@')) return 'Geçerli e-posta girin';
                      return null;
                    },
                  ),
                  if (!widget.isEdit) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sifreCtrl,
                      obscureText: true,
                      decoration: _fieldDeco(
                        'Şifre',
                        helper:
                            'Firebase Authentication üzerinden atanır.',
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Şifre en az 6 karakter olmalı'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _rol,
                    decoration: _fieldDeco('Rol'),
                    items: const [
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'Kasiyer', child: Text('Kasiyer')),
                    ],
                    onChanged: self
                        ? null
                        : (v) => setState(() => _rol = v ?? 'Kasiyer'),
                  ),
                  if (self)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Kendi rolünüzü buradan değiştiremezsiniz.',
                        style: TextStyle(fontSize: 12, color: HesapixColors.textMuted),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Aktif',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: self
                        ? const Text(
                            'Kendi hesabınızı pasife alamazsınız',
                            style: TextStyle(fontSize: 12),
                          )
                        : null,
                    value: _aktif,
                    activeThumbColor: HesapixColors.accent,
                    onChanged: self ? null : (v) => setState(() => _aktif = v),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _loading ? null : () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: HesapixColors.primary,
                            side: const BorderSide(color: HesapixColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: HesapixColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(_loading ? 'Kaydediliyor…' : 'Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDeco(String label, {String? helper}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 3,
      filled: true,
      fillColor: HesapixColors.bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HesapixColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HesapixColors.primary, width: 1.5),
      ),
    );
  }

  String _fmtStatic(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
