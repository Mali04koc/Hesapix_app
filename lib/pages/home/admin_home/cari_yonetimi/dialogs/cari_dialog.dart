import 'package:flutter/material.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

class CariDialog extends StatefulWidget {
  final Cari? existingCari;
  final Function(Cari cariData) onSubmit;

  const CariDialog({super.key, this.existingCari, required this.onSubmit});

  @override
  State<CariDialog> createState() => _CariDialogState();
}

class _CariDialogState extends State<CariDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cariKoduCtrl;
  late TextEditingController _firmaAdiCtrl;
  late TextEditingController _vergiNoCtrl;
  late TextEditingController _mailCtrl;
  late TextEditingController _adresCtrl;
  late TextEditingController _bakiyeCtrl;

  @override
  void initState() {
    super.initState();
    _cariKoduCtrl = TextEditingController(text: widget.existingCari?.cariKodu ?? '');
    _firmaAdiCtrl = TextEditingController(text: widget.existingCari?.firmaAdi ?? '');
    _vergiNoCtrl = TextEditingController(text: widget.existingCari?.vergiNo ?? '');
    _mailCtrl = TextEditingController(text: widget.existingCari?.mail ?? '');
    _adresCtrl = TextEditingController(text: widget.existingCari?.adres ?? '');
    _bakiyeCtrl = TextEditingController(text: widget.existingCari?.bakiye.toString() ?? '0');
  }

  @override
  void dispose() {
    _cariKoduCtrl.dispose();
    _firmaAdiCtrl.dispose();
    _vergiNoCtrl.dispose();
    _mailCtrl.dispose();
    _adresCtrl.dispose();
    _bakiyeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final data = Cari(
        id: widget.existingCari?.id,
        cariKodu: _cariKoduCtrl.text.trim(),
        firmaAdi: _firmaAdiCtrl.text.trim(),
        vergiNo: _vergiNoCtrl.text.trim(),
        mail: _mailCtrl.text.trim(),
        adres: _adresCtrl.text.trim(),
        bakiye: double.tryParse(_bakiyeCtrl.text.trim()) ?? 0.0,
      );
      widget.onSubmit(data);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingCari != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Cari Düzenle' : 'Yeni Cari Ekle', style: const TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _cariKoduCtrl,
                decoration: const InputDecoration(labelText: 'Cari Kodu', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Cari kodu zorunludur' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _firmaAdiCtrl,
                decoration: const InputDecoration(labelText: 'Firma Adı', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Firma adı zorunludur' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vergiNoCtrl,
                decoration: const InputDecoration(labelText: 'Vergi No', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mailCtrl,
                decoration: const InputDecoration(labelText: 'Mail Adresi', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adresCtrl,
                decoration: const InputDecoration(labelText: 'Adres', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bakiyeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Başlangıç Bakiyesi (₺)', border: OutlineInputBorder()),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Bakiye zorunludur';
                  if (double.tryParse(val) == null) return 'Geçerli bir sayı girin';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: HesapixColors.primary, foregroundColor: Colors.white),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
