import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/services/rapor_service.dart';
import 'package:hesapix_app/models/satis_model.dart';
import 'package:hesapix_app/models/satis_detay_model.dart';

class SatisRaporlariPage extends StatefulWidget {
  const SatisRaporlariPage({super.key});

  @override
  State<SatisRaporlariPage> createState() => _SatisRaporlariPageState();
}

class _SatisRaporlariPageState extends State<SatisRaporlariPage> {
  final RaporService _raporService = RaporService();
  
  DateTime _baslangic = DateTime.now().subtract(const Duration(days: 30));
  DateTime _bitis = DateTime.now();
  
  List<Satis> _satislar = [];
  List<SatisDetay> _detaylar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verileriGetir();
  }

  Future<void> _verileriGetir() async {
    setState(() => _isLoading = true);
    try {
      _satislar = await _raporService.getSatislar(_baslangic, _bitis);
      _detaylar = await _raporService.getSatisDetaylari(_baslangic, _bitis);
    } catch (e) {
      debugPrint('Satis Rapor Hatasi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _tarihSec(BuildContext context, bool isBaslangic) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isBaslangic ? _baslangic : _bitis,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isBaslangic) {
          _baslangic = picked;
        } else {
          // Günü tam kapsaması için
          _bitis = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
      _verileriGetir();
    }
  }

  @override
  Widget build(BuildContext context) {
    double toplamCiro = _satislar.fold(0, (sum, item) => sum + item.genelToplam);
    double nakit = _satislar.where((s) => s.odemeTuru == 'Nakit').fold(0, (sum, s) => sum + s.genelToplam);
    double kart = _satislar.where((s) => s.odemeTuru == 'Kart').fold(0, (sum, s) => sum + s.genelToplam);
    double acik = _satislar.where((s) => s.odemeTuru == 'Açık Hesap').fold(0, (sum, s) => sum + s.genelToplam);

    // Ürün bazlı gruplama
    Map<String, int> urunSatisMiktarlari = {};
    for (var d in _detaylar) {
      urunSatisMiktarlari[d.urunAdi] = (urunSatisMiktarlari[d.urunAdi] ?? 0) + d.miktar;
    }
    var siraliUrunler = urunSatisMiktarlari.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final top5 = siraliUrunler.take(5).toList();

    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Satış Raporları', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Filtre Alanı
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () => _tarihSec(context, true),
                  icon: const Icon(Icons.date_range),
                  label: Text('${_baslangic.day}.${_baslangic.month}.${_baslangic.year}'),
                ),
                const Text('-'),
                TextButton.icon(
                  onPressed: () => _tarihSec(context, false),
                  icon: const Icon(Icons.date_range),
                  label: Text('${_bitis.day}.${_bitis.month}.${_bitis.year}'),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Özet Kartları
                        Row(
                          children: [
                            _ozetKarti('Toplam Ciro', '₺${toplamCiro.toStringAsFixed(2)}', Colors.blue),
                            const SizedBox(width: 16),
                            _ozetKarti('Toplam Fatura', '${_satislar.length}', Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Ödeme Dağılımı (Pie Chart)
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ödeme Türü Dağılımı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: toplamCiro == 0 ? const Center(child: Text('Veri yok')) : PieChart(
                                    PieChartData(
                                      sections: [
                                        if (nakit > 0) PieChartSectionData(color: Colors.green, value: nakit, title: 'Nakit\n%${(nakit/toplamCiro*100).toStringAsFixed(1)}', radius: 60),
                                        if (kart > 0) PieChartSectionData(color: Colors.blue, value: kart, title: 'Kart\n%${(kart/toplamCiro*100).toStringAsFixed(1)}', radius: 60),
                                        if (acik > 0) PieChartSectionData(color: Colors.red, value: acik, title: 'Açık\n%${(acik/toplamCiro*100).toStringAsFixed(1)}', radius: 60),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // En Çok Satan Ürünler
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('En Çok Satan Ürünler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                if (top5.isEmpty) const Text('Veri yok') else ...top5.map((e) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(e.key),
                                      Text('${e.value} adet', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _ozetKarti(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
