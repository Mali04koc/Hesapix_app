import 'package:flutter/material.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/urun_model.dart';
import 'package:hesapix_app/core/database/service_locator.dart';
import 'package:hesapix_app/services/interfaces/i_urun_service.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/pages/home/admin_home/fiyat_gor/fiyat_gor_page.dart'; // BarcodeScannerPage için
import 'package:hesapix_app/pages/home/admin_home/satis_arayuz/satis_faturasi_odeme_page.dart';

class SatisFaturasiDetayPage extends StatefulWidget {
  final Cari cari;

  const SatisFaturasiDetayPage({super.key, required this.cari});

  @override
  State<SatisFaturasiDetayPage> createState() => _SatisFaturasiDetayPageState();
}

class _SatisFaturasiDetayPageState extends State<SatisFaturasiDetayPage> {
  final IUrunService _urunService = ServiceLocator.urunService;
  final TextEditingController _aramaCtrl = TextEditingController();
  
  bool _isLoading = false;
  Urun? _bulunanUrun;
  String _hataMesaji = '';
  
  int _adet = 1;
  final TextEditingController _adetCtrl = TextEditingController(text: '1');
  final List<Map<String, dynamic>> _sepet = [];

  @override
  void dispose() {
    _aramaCtrl.dispose();
    _adetCtrl.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? HesapixColors.danger : HesapixColors.success,
      ),
    );
  }

  Future<void> _barkodOkut() async {
    try {
      final code = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
      );

      if (code != null && code.isNotEmpty) {
        _aramaCtrl.text = code;
        _urunAra(code);
      }
    } catch (e) {
      _snack('Barkod okuyucu hatası: $e', error: true);
    }
  }

  Future<void> _urunAra(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hataMesaji = '';
      _bulunanUrun = null;
    });
    try {
      final urunler = await _urunService.urunAra(query);
      setState(() {
        _isLoading = false;
        if (urunler.isNotEmpty) {
          final tamEslesen = urunler.firstWhere(
            (u) => u.barkod == query || u.urunKodu == query,
            orElse: () => urunler.first,
          );
          _bulunanUrun = tamEslesen;
          _adet = 1;
          _adetCtrl.text = '1';
        } else {
          _hataMesaji = 'Ürün bulunamadı!';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hataMesaji = 'Hata: $e';
      });
    }
  }

  void _sepeteEkle() {
    if (_bulunanUrun == null) return;
    final urun = _bulunanUrun!;
    final miktar = _adet;
    // Stok kontrolü
    int sepettekiMiktar = 0;
    for (var item in _sepet) {
      if (item['urun'].id == urun.id) {
        sepettekiMiktar += (item['adet'] as int);
      }
    }
    
    if (urun.stok < (sepettekiMiktar + miktar)) {
      _snack('"${urun.isim}" ürününden stokta yalnızca ${urun.stok} adet var!', error: true);
      return;
    }
    
    setState(() {
      bool sepetteVar = false;
      for (var item in _sepet) {
        if (item['urun'].id == urun.id) {
          item['adet'] += miktar;
          item['araToplam'] = item['araToplam'] + (item['araToplam'] / (item['adet'] - miktar) * miktar); // Basitçe miktar bazlı oranlama yerine tekrar hesaplamak daha güvenli
          
          // KDV Hesaplama (KDV Dahil fiyattan geri gidiyoruz)
          double kdvOrani = 20.0;
          double satisFiyat = urun.satisFiyat;
          double araBirimFiyat = satisFiyat / (1 + (kdvOrani / 100));
          double kdvBirimTutar = satisFiyat - araBirimFiyat;
          
          item['araToplam'] = araBirimFiyat * item['adet'];
          item['kdvTutar'] = kdvBirimTutar * item['adet'];
          item['toplam'] = satisFiyat * item['adet'];
          sepetteVar = true;
          break;
        }
      }
      
      if (!sepetteVar) {
        double kdvOrani = 20.0;
        double satisFiyat = urun.satisFiyat;
        double araBirimFiyat = satisFiyat / (1 + (kdvOrani / 100));
        double kdvBirimTutar = satisFiyat - araBirimFiyat;

        _sepet.add({
          'urun': urun,
          'adet': miktar,
          'fiyat': satisFiyat,
          'kdvOrani': kdvOrani,
          'araToplam': araBirimFiyat * miktar,
          'kdvTutar': kdvBirimTutar * miktar,
          'toplam': satisFiyat * miktar,
        });
      }
    });
    
    _snack('${urun.isim} sepete eklendi.');

    setState(() {
      _bulunanUrun = null;
      _aramaCtrl.clear();
      _adet = 1;
      _adetCtrl.text = '1';
    });
  }

  void _odemeEkraninaGec() {
    if (_sepet.isEmpty) {
      _snack('Sepetiniz boş. Lütfen ürün ekleyin.', error: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SatisFaturasiOdemePage(cari: widget.cari, sepet: _sepet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: _odemeEkraninaGec,
              child: Badge(
                label: Text('${_sepet.length}'),
                isLabelVisible: _sepet.isNotEmpty,
                backgroundColor: Colors.red,
                child: const Icon(Icons.shopping_cart, color: HesapixColors.primary, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Fatura: ${widget.cari.firmaAdi}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: HesapixColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Autocomplete<Urun>(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Urun>.empty();
                      }
                      try {
                        final products = await _urunService.urunAra(textEditingValue.text);
                        return products;
                      } catch (e) {
                        return const Iterable<Urun>.empty();
                      }
                    },
                    displayStringForOption: (Urun option) => option.isim,
                    onSelected: (Urun selection) {
                      setState(() {
                        _bulunanUrun = selection;
                        _adet = 1;
                        _adetCtrl.text = '1';
                        _hataMesaji = '';
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Barkod, Ürün Adı veya Kodu (Yazmaya başlayın)',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onSubmitted: (value) async {
                          await _urunAra(value);
                          controller.clear();
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 250),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option.isim, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Barkod: ${option.barkod} | Stok: ${option.stok} | Fiyat: ₺${option.satisFiyat.toStringAsFixed(2)}'),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: HesapixColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _barkodOkut,
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                    tooltip: 'Kamerayla Barkod Oku',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_hataMesaji.isNotEmpty)
              Text(
                _hataMesaji,
                style: const TextStyle(color: HesapixColors.danger, fontSize: 18, fontWeight: FontWeight.bold),
              )
            else if (_bulunanUrun != null)
              _buildUrunKart(_bulunanUrun!),
          ],
        ),
      ),
    );
  }

  Widget _buildUrunKart(Urun u) {
    double toplamFiyat = u.satisFiyat * _adet;
    
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200, width: 2)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (u.gorsel.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  u.gorsel,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120, width: 120,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              u.isim,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Barkod: ${u.barkod} | Stok: ${u.stok}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Adet ve Fiyat Alanı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HesapixColors.bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Birim Fiyat:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                      Text('₺${u.satisFiyat.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Adet:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_adet > 1) {
                                setState(() {
                                  _adet--;
                                  _adetCtrl.text = _adet.toString();
                                });
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline, color: HesapixColors.primary),
                          ),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _adetCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                int? parsed = int.tryParse(val);
                                if (parsed != null && parsed > 0) {
                                  setState(() => _adet = parsed);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _adet++;
                                _adetCtrl.text = _adet.toString();
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline, color: HesapixColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Toplam:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text('₺${toplamFiyat.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: HesapixColors.success)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sepeteEkle,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Sepete Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HesapixColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}
