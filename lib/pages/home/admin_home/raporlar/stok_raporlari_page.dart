import 'package:flutter/material.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/services/rapor_service.dart';
import 'package:hesapix_app/models/urun_model.dart';

class StokRaporlariPage extends StatefulWidget {
  const StokRaporlariPage({super.key});

  @override
  State<StokRaporlariPage> createState() => _StokRaporlariPageState();
}

class _StokRaporlariPageState extends State<StokRaporlariPage> {
  final RaporService _raporService = RaporService();
  
  List<Urun> _urunler = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verileriGetir();
  }

  Future<void> _verileriGetir() async {
    setState(() => _isLoading = true);
    try {
      _urunler = await _raporService.getTumUrunler();
      // Stok miktarına göre çoktan aza sırala
      _urunler.sort((a, b) => b.stok.compareTo(a.stok));
    } catch (e) {
      debugPrint('Stok Rapor Hatasi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int toplamUrunCesidi = _urunler.length;
    int kritikStokSayisi = _urunler.where((u) => u.stok < 10).length; // 10'un altı kritik sayıyoruz
    int toplamStokAdedi = _urunler.fold(0, (sum, u) => sum + u.stok);
    double toplamStokMaliyeti = _urunler.fold(0.0, (sum, u) => sum + (u.stok * (u.alisFiyat ?? 0.0)));

    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Stok Raporları', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Özet Kartları
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _ozetKarti('Toplam Çeşit', '$toplamUrunCesidi', Colors.blue),
                      const SizedBox(width: 12),
                      _ozetKarti('Toplam Adet', '$toplamStokAdedi', Colors.green),
                      const SizedBox(width: 12),
                      _ozetKarti('Kritik Stok', '$kritikStokSayisi', Colors.red),
                    ],
                  ),
                ),
                
                // Toplam Maliyet
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Depo Maliyet Değeri', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('₺${toplamStokMaliyeti.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tablo Başlıkları
                Container(
                  color: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('Ürün Adı', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Alış(₺)', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text('Satış(₺)', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text('Mevcut', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    ],
                  ),
                ),

                // Ürün Listesi
                Expanded(
                  child: ListView.builder(
                    itemCount: _urunler.length,
                    itemBuilder: (context, index) {
                      final u = _urunler[index];
                      final isKritik = u.stok < 10;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                          color: isKritik ? Colors.red.shade50 : Colors.white,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3, 
                              child: Row(
                                children: [
                                  if (isKritik) const Icon(Icons.warning, color: Colors.red, size: 16),
                                  if (isKritik) const SizedBox(width: 4),
                                  Expanded(child: Text(u.isim, overflow: TextOverflow.ellipsis, style: TextStyle(color: isKritik ? Colors.red.shade900 : Colors.black))),
                                ],
                              )
                            ),
                            Expanded(flex: 2, child: Text(u.alisFiyat?.toStringAsFixed(2) ?? '-', textAlign: TextAlign.right)),
                            Expanded(flex: 2, child: Text(u.satisFiyat.toStringAsFixed(2), textAlign: TextAlign.right)),
                            Expanded(
                              flex: 2, 
                              child: Text(
                                '${u.stok}', 
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isKritik ? Colors.red : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _ozetKarti(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
