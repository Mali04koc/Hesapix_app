import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hesapix_app/models/urun_model.dart';
import 'package:hesapix_app/models/kategori_model.dart';
import 'package:hesapix_app/models/tedarikci_model.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

class UrunDialogData {
  final String isim;
  final double alisFiyat;
  final double satisFiyat;
  final int stok;
  final String barkod;
  final String kategoriId;
  final String gorselUrl;
  final String urunKodu;
  final String tedarikciKodu;

  UrunDialogData({
    required this.isim,
    required this.alisFiyat,
    required this.satisFiyat,
    required this.stok,
    required this.barkod,
    required this.kategoriId,
    required this.gorselUrl,
    required this.urunKodu,
    required this.tedarikciKodu,
  });
}

class UrunDialog extends StatefulWidget {
  const UrunDialog({
    super.key,
    this.existingUrun,
    required this.kategoriler,
    required this.tedarikciler,
    required this.onSubmit,
  });

  final Urun? existingUrun;
  final List<Kategori> kategoriler;
  final List<Tedarikci> tedarikciler;
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
  late TextEditingController _urunKoduCtrl;
  late TextEditingController _tedarikciKoduCtrl;
  late TextEditingController _barkodCtrl;

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
    _urunKoduCtrl = TextEditingController(text: u?.urunKodu ?? '');
    _tedarikciKoduCtrl = TextEditingController(text: u?.tedarikciKodu ?? '');
    _barkodCtrl = TextEditingController(text: u?.barkod ?? '');
    
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
    _urunKoduCtrl.dispose();
    _tedarikciKoduCtrl.dispose();
    _barkodCtrl.dispose();
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

      final data = UrunDialogData(
        isim: _isimCtrl.text.trim(),
        alisFiyat: double.tryParse(_alisFiyatCtrl.text.trim()) ?? 0.0,
        satisFiyat: double.tryParse(_satisFiyatCtrl.text.trim()) ?? 0.0,
        stok: int.tryParse(_stokCtrl.text.trim()) ?? 0,
        barkod: _barkodCtrl.text.trim(),
        kategoriId: _selectedKategoriId!,
        gorselUrl: _gorselUrlCtrl.text.trim(),
        urunKodu: _urunKoduCtrl.text.trim(),
        tedarikciKodu: _tedarikciKoduCtrl.text.trim(),
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
                TextFormField(
                  controller: _urunKoduCtrl,
                  decoration: InputDecoration(
                    labelText: 'Ürün Kodu',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Boş bırakılamaz' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Autocomplete<Tedarikci>(
                        displayStringForOption: (Tedarikci option) => option.tedarikciKodu,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') {
                            return widget.tedarikciler;
                          }
                          return widget.tedarikciler.where((Tedarikci option) {
                            return option.tedarikciKodu.contains(textEditingValue.text);
                          });
                        },
                        onSelected: (Tedarikci selection) {
                          _tedarikciKoduCtrl.text = selection.tedarikciKodu;
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          if (_tedarikciKoduCtrl.text.isNotEmpty && textEditingController.text.isEmpty) {
                            textEditingController.text = _tedarikciKoduCtrl.text;
                          }
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Tedarikçi Kodu',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Boş bırakılamaz' : null,
                            onChanged: (v) {
                              _tedarikciKoduCtrl.text = v;
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _barkodCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Barkod',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Boş bırakılamaz';
                          if (v.trim().length > 13) return 'En fazla 13 rakam girilebilir';
                          return null;
                        },
                      ),
                    ),
                  ],
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
                Autocomplete<Kategori>(
                  displayStringForOption: (Kategori option) => option.isim,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return widget.kategoriler;
                    }
                    return widget.kategoriler.where((Kategori option) {
                      return option.isim.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (Kategori selection) {
                    setState(() {
                      _selectedKategoriId = selection.id;
                    });
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    if (_selectedKategoriId != null && textEditingController.text.isEmpty) {
                      final existingCat = widget.kategoriler.where((k) => k.id == _selectedKategoriId).firstOrNull;
                      if (existingCat != null) {
                        textEditingController.text = existingCat.isim;
                      }
                    }
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Kategori Seç (Yazarak Arayın)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        if (_selectedKategoriId == null) return 'Lütfen listeden kategori seçiniz';
                        return null;
                      },
                      onChanged: (v) {
                        setState(() {
                          _selectedKategoriId = null;
                        });
                      },
                    );
                  },
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
