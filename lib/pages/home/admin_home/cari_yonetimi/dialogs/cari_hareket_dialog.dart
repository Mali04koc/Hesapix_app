import 'package:flutter/material.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

class CariHareketDialog extends StatefulWidget {
  final String cariId;
  final Function(CariHareket hareket) onSubmit;

  const CariHareketDialog({super.key, required this.cariId, required this.onSubmit});

  @override
  State<CariHareketDialog> createState() => _CariHareketDialogState();
}

class _CariHareketDialogState extends State<CariHareketDialog> {
  final _formKey = GlobalKey<FormState>();
  String _secilenIslemTipi = 'SATIS';
  late TextEditingController _tutarCtrl;
  late TextEditingController _aciklamaCtrl;

  final List<String> _islemTipleri = [
    'SATIS',
    'ALIS',
    'ODEME_AL',
    'ODEME_YAP'
  ];

  @override
  void initState() {
    super.initState();
    _tutarCtrl = TextEditingController();
    _aciklamaCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tutarCtrl.dispose();
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final hareket = CariHareket(
        cariId: widget.cariId,
        islemTipi: _secilenIslemTipi,
        tarih: DateTime.now(),
        tutar: double.tryParse(_tutarCtrl.text.trim()) ?? 0.0,
        aciklama: _aciklamaCtrl.text.trim(),
      );
      widget.onSubmit(hareket);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('İşlem Ekle', style: TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _secilenIslemTipi,
                decoration: const InputDecoration(labelText: 'İşlem Tipi', border: OutlineInputBorder()),
                items: _islemTipleri.map((String tip) {
                  return DropdownMenuItem<String>(
                    value: tip,
                    child: Text(tip),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _secilenIslemTipi = newValue!;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tutarCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Tutar (₺)', border: OutlineInputBorder()),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Tutar zorunludur';
                  if (double.tryParse(val) == null) return 'Geçerli bir sayı girin';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aciklamaCtrl,
                decoration: const InputDecoration(labelText: 'Açıklama', border: OutlineInputBorder()),
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
