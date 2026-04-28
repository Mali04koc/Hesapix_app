import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hesapix_app/models/tedarikci_model.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

class TedarikciDialogData {
  final String isim;
  final String telefon;
  final String adres;
  final double borc;
  final String tedarikciKodu;
  final int taksit;
  final double aylikOdeme;

  TedarikciDialogData({
    required this.isim,
    required this.telefon,
    required this.adres,
    required this.borc,
    required this.tedarikciKodu,
    required this.taksit,
    required this.aylikOdeme,
  });
}

class TedarikciDialog extends StatefulWidget {
  const TedarikciDialog({
    super.key,
    this.existingTedarikci,
    required this.onSubmit,
  });

  final Tedarikci? existingTedarikci;
  final Future<void> Function(TedarikciDialogData data) onSubmit;

  @override
  State<TedarikciDialog> createState() => _TedarikciDialogState();
}

class _TedarikciDialogState extends State<TedarikciDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _isimCtrl;
  late TextEditingController _telefonCtrl;
  late TextEditingController _adresCtrl;
  late TextEditingController _borcCtrl;
  late TextEditingController _tedarikciKoduCtrl;
  late TextEditingController _taksitCtrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTedarikci;
    _isimCtrl = TextEditingController(text: t?.isim ?? '');
    _telefonCtrl = TextEditingController(text: t?.telefon ?? '');
    _adresCtrl = TextEditingController(text: t?.adres ?? '');
    _borcCtrl = TextEditingController(text: t?.borc.toString() ?? '0');
    _tedarikciKoduCtrl = TextEditingController(text: t?.tedarikciKodu ?? '');
    _taksitCtrl = TextEditingController(text: t?.taksit.toString() ?? '');
  }

  @override
  void dispose() {
    _isimCtrl.dispose();
    _telefonCtrl.dispose();
    _adresCtrl.dispose();
    _borcCtrl.dispose();
    _tedarikciKoduCtrl.dispose();
    _taksitCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      double borcVal = double.tryParse(_borcCtrl.text.trim()) ?? 0.0;
      int taksitVal = int.tryParse(_taksitCtrl.text.trim()) ?? 0;

      if (borcVal > 0 && taksitVal == 0) {
        throw Exception('Borç 0\'dan büyükse taksit en az 1 olmalıdır.');
      }

      double aylikOdemeVal = taksitVal > 0 ? borcVal / taksitVal : 0.0;

      final data = TedarikciDialogData(
        isim: _isimCtrl.text.trim(),
        telefon: _telefonCtrl.text.trim(),
        adres: _adresCtrl.text.trim(),
        borc: borcVal,
        tedarikciKodu: _tedarikciKoduCtrl.text.trim(),
        taksit: taksitVal,
        aylikOdeme: aylikOdemeVal,
      );

      await widget.onSubmit(data);
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
    final isEdit = widget.existingTedarikci != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Tedarikçi Düzenle' : 'Yeni Tedarikçi',
        style: const TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _tedarikciKoduCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tedarikçi Kodu',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Boş bırakılamaz' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _isimCtrl,
                  decoration: InputDecoration(
                    labelText: 'İsim / Firma Adı',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Boş bırakılamaz' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Telefon',
                    prefixText: '+90 ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Boş bırakılamaz';
                    if (v.trim().length != 10) return '10 haneli olmalıdır (Örn: 5427181827)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _adresCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Adres',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Boş bırakılamaz' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _borcCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Mevcut Borç (₺)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Giriniz' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _taksitCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Taksit',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Boş bırakılamaz';
                          if (v.trim().length > 2) return 'En fazla 2 rakam';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
