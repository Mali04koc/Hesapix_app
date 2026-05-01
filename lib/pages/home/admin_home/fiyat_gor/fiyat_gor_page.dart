import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hesapix_app/models/urun_model.dart';
import 'package:hesapix_app/services/urun_service.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

class FiyatGorPage extends StatefulWidget {
  const FiyatGorPage({super.key});

  @override
  State<FiyatGorPage> createState() => _FiyatGorPageState();
}

class _FiyatGorPageState extends State<FiyatGorPage> {
  final UrunService _urunService = UrunService();
  final TextEditingController _aramaCtrl = TextEditingController();
  
  bool _isLoading = false;
  Urun? _bulunanUrun;
  String _hataMesaji = '';

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
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
      });
      return;
    }

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
          // Barkodu veya ürün kodu tam eşleşeni önceliklendir
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Fiyat Gör', style: TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: HesapixColors.primary),
      ),
      body: Padding(
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
            const SizedBox(height: 48),
            
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
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150, width: 150,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              u.isim,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stok Kodu: ${u.urunKodu}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            if (u.barkod.isNotEmpty)
              Text(
                'Barkod: ${u.barkod}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              decoration: BoxDecoration(
                color: HesapixColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HesapixColors.success.withOpacity(0.3), width: 2),
              ),
              child: Text(
                '₺${u.satisFiyat.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: HesapixColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarcodeScannerPage extends StatelessWidget {
  const BarcodeScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Barkod Tara"),
        backgroundColor: Colors.white,
      ),
      body: MobileScanner(
        onDetect: (barcodeCapture) {
          if (barcodeCapture.barcodes.isNotEmpty) {
            final barcode = barcodeCapture.barcodes.first;
            final String? code = barcode.rawValue;

            if (code != null) {
              Navigator.pop(context, code);
            }
          }
        },
      ),
    );
  }
}
