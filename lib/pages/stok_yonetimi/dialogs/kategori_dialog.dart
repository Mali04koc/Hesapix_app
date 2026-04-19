import 'package:flutter/material.dart';
import 'package:hesapix_app/models/kategori_model.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

class KategoriDialog extends StatefulWidget {
  const KategoriDialog({
    super.key,
    this.existingKategori,
    required this.onSubmit,
  });

  final Kategori? existingKategori;
  final Future<void> Function(String isim) onSubmit;

  @override
  State<KategoriDialog> createState() => _KategoriDialogState();
}

class _KategoriDialogState extends State<KategoriDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _isimCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isimCtrl = TextEditingController(text: widget.existingKategori?.isim ?? '');
  }

  @override
  void dispose() {
    _isimCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(_isimCtrl.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: HesapixColors.danger,
            content: Text('Hata: $e')
          ),
        );
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingKategori != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Kategori Düzenle' : 'Yeni Kategori',
        style: const TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _isimCtrl,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Kategori Adı',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Kategori adı giriniz' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('İptal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: HesapixColors.accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
