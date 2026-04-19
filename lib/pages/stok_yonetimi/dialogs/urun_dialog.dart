import 'package:flutter/material.dart';
import 'package:hesapix_app/models/urun_model.dart';
import 'package:hesapix_app/models/kategori_model.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

class UrunDialogData {
  final String isim;
  final double alisFiyat;
  final double satisFiyat;
  final int stok;
  final String barkod;
  final String kategoriId;
  final String gorselUrl;

  UrunDialogData({
    required this.isim,
    required this.alisFiyat,
    required this.satisFiyat,
    required this.stok,
    required this.barkod,
    required this.kategoriId,
    required this.gorselUrl,
  });
}

class UrunDialog extends StatefulWidget {
  const UrunDialog({
    super.key,
    this.existingUrun,
    required this.kategoriler,
    required this.onSubmit,
  });

  final Urun? existingUrun;
  final List<Kategori> kategoriler;
  final Future<void> Function(UrunDialogData data) onSubmit;

  @override
  State<UrunDialog> createState() => _UrunDialogState();
}

class _UrunDialogState extends State<UrunDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _isimCtrl;
  late TextEditingController _alisFiyatCtrl;
  late TextEditingController _satisFiyatCtrl;
  late TextEditingController _stokCtrl;
  late TextEditingController _gorselUrlCtrl;

  String? _selectedKategoriId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final u = widget.existingUrun;
    _isimCtrl = TextEditingController(text: u?.isim ?? '');
    _alisFiyatCtrl = TextEditingController(text: u?.alisFiyat.toString() ?? '');
    _satisFiyatCtrl = TextEditingController(text: u?.satisFiyat.toString() ?? '');
    _stokCtrl = TextEditingController(text: u?.stok.toString() ?? '');
    _gorselUrlCtrl = TextEditingController(text: u?.gorsel ?? '');
    
    if (u != null) {
      if (widget.kategoriler.any((k) => k.id == u.kategoriId)) {
        _selectedKategoriId = u.kategoriId;
      }
    }
    
    if (_selectedKategoriId == null && widget.kategoriler.isNotEmpty) {
      _selectedKategoriId = widget.kategoriler.first.id;
    }
  }

  @override
  void dispose() {
    _isimCtrl.dispose();
    _alisFiyatCtrl.dispose();
    _satisFiyatCtrl.dispose();
    _stokCtrl.dispose();
    _gorselUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kategori seçiniz.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {

      String finalBarkod = widget.existingUrun?.barkod ?? DateTime.now().millisecondsSinceEpoch.toString();

      final data = UrunDialogData(
        isim: _isimCtrl.text.trim(),
        alisFiyat: double.tryParse(_alisFiyatCtrl.text.trim()) ?? 0.0,
        satisFiyat: double.tryParse(_satisFiyatCtrl.text.trim()) ?? 0.0,
        stok: int.tryParse(_stokCtrl.text.trim()) ?? 0,
        barkod: finalBarkod,
        kategoriId: _selectedKategoriId!,
        gorselUrl: _gorselUrlCtrl.text.trim(),
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
    final isEdit = widget.existingUrun != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Ürün Düzenle' : 'Yeni Ürün',
        style: const TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _gorselUrlCtrl,
                  decoration: InputDecoration(
                    labelText: 'Görsel URL (Opsiyonel)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _isimCtrl,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Ürün Adı',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Boş bırakılamaz' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _alisFiyatCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Alış Fiyatı (₺)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Giriniz' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _satisFiyatCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Satış Fiyatı (₺)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Giriniz' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stokCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Stok Adedi',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Giriniz' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedKategoriId,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: widget.kategoriler.map((k) {
                    return DropdownMenuItem(
                      value: k.id,
                      child: Text(k.isim),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedKategoriId = val;
                    });
                  },
                  validator: (v) => v == null ? 'Kategori seçiniz' : null,
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
