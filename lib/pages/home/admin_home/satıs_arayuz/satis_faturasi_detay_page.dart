import 'package:flutter/material.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/urun_model.dart';
import 'package:hesapix_app/services/urun_service.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/pages/home/admin_home/fiyat_gor/fiyat_gor_page.dart'; // BarcodeScannerPage için
import 'package:hesapix_app/pages/home/admin_home/satıs_arayuz/satis_faturasi_odeme_page.dart';

class SatisFaturasiDetayPage extends StatefulWidget {
  final Cari cari;

  const SatisFaturasiDetayPage({super.key, required this.cari});

  @override
  State<SatisFaturasiDetayPage> createState() => _SatisFaturasiDetayPageState();
}

class _SatisFaturasiDetayPageState extends State<SatisFaturasiDetayPage> {
  final UrunService _urunService = UrunService();
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
      setState(() {
        _hataMesaji = 'Barkod okuyucu başlatılamadı.';
        _bulunanUrun = null;
      });
    }
  }

  Future<void> _urunAra(String arama) async {
    final query = arama.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _bulunanUrun = null;
        _hataMesaji = '';
        _adet = 1;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hataMesaji = '';
      _bulunanUrun = null;
      _adet = 1;
    });

    try {
      final urunler = await _urunService.urunAra(query);
      
      setState(() {
        _isLoading = false;
        if (urunler.isNotEmpty) {
          final tamEslesen = urunler.where((u) => 
            u.barkod.toLowerCase() == query || 
            u.urunKodu.toLowerCase() == query
          ).firstOrNull;
          
          _bulunanUrun = tamEslesen ?? urunler.first;
        } else {
          _hataMesaji = 'Ürün bulunamadı.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hataMesaji = 'Arama sırasında bir hata oluştu.';
      });
    }
  }

  void _sepeteEkle() {
    if (_bulunanUrun == null) return;
    
    // Sepette bu üründen halihazırda kaç tane var bulalım
    int sepettekiMiktar = 0;
    for (var item in _sepet) {
      if (item['urun'].id == _bulunanUrun!.id) {
        sepettekiMiktar += (item['adet'] as int);
      }
    }
    
    int istenenToplamMiktar = sepettekiMiktar + _adet;
    
    // Stok kontrolü
    if (_bulunanUrun!.stok < istenenToplamMiktar) {
      _snack('"${_bulunanUrun!.isim}" ürününden stokta yalnızca ${_bulunanUrun!.stok} adet var!', error: true);
      return;
    }
    
    setState(() {
      // Eğer sepette zaten varsa miktarını artıralım (daha temiz bir sepet görünümü için)
      bool sepetteVar = false;
      for (var item in _sepet) {
        if (item['urun'].id == _bulunanUrun!.id) {
          item['adet'] += _adet;
          item['toplam'] = item['fiyat'] * item['adet'];
          sepetteVar = true;
          break;
        }
      }
      
      if (!sepetteVar) {
        _sepet.add({
          'urun': _bulunanUrun,
          'adet': _adet,
          'fiyat': _bulunanUrun!.satisFiyat,
          'toplam': _bulunanUrun!.satisFiyat * _adet,
        });
      }
    });
    
    _snack('${_bulunanUrun!.isim} sepete eklendi.');
    
    setState(() {
      _bulunanUrun = null;
      _aramaCtrl.clear();
      _adet = 1;
      _adetCtrl.text = '1';
      _hataMesaji = '';
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
                  child: TextField(
                    controller: _aramaCtrl,
                    decoration: InputDecoration(
                      hintText: 'Barkod, Ürün Adı veya Kodu Girin',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: HesapixColors.primary, width: 2),
                      ),
                    ),
                    onSubmitted: _urunAra,
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _urunAra(_aramaCtrl.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HesapixColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Ara', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
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
              'Stok Kodu: ${u.urunKodu} | Barkod: ${u.barkod}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
