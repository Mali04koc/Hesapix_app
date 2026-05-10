import 'package:flutter/material.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/services/rapor_service.dart';
import 'package:hesapix_app/models/alis_model.dart';
import 'package:hesapix_app/models/alis_detay_model.dart';
import 'package:hesapix_app/models/cari_model.dart';

class AlisRaporlariPage extends StatefulWidget {
  const AlisRaporlariPage({super.key});

  @override
  State<AlisRaporlariPage> createState() => _AlisRaporlariPageState();
}

class _AlisRaporlariPageState extends State<AlisRaporlariPage> {
  final RaporService _raporService = RaporService();
  
  DateTime _baslangic = DateTime.now().subtract(const Duration(days: 30));
  DateTime _bitis = DateTime.now();
  
  List<Alis> _alislar = [];
  List<AlisDetay> _detaylar = [];
  List<Cari> _cariler = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verileriGetir();
  }

  Future<void> _verileriGetir() async {
    setState(() => _isLoading = true);
    try {
      _alislar = await _raporService.getAlislar(_baslangic, _bitis);
      _detaylar = await _raporService.getAlisDetaylari(_baslangic, _bitis);
      _cariler = await _raporService.getCariler();
    } catch (e) {
      debugPrint('Alis Rapor Hatasi: $e');
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
          _bitis = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
      _verileriGetir();
    }
  }

  String _cariAdiGetir(String cariId) {
    try {
      return _cariler.firstWhere((c) => c.id == cariId).firmaAdi;
    } catch (e) {
      return 'Bilinmeyen Tedarikçi';
    }
  }

  @override
  Widget build(BuildContext context) {
    double toplamAlis = _alislar.fold(0, (sum, item) => sum + item.genelToplam);
    
    // Tedarikçi bazlı gruplama
    Map<String, double> tedarikciAlislari = {};
    for (var a in _alislar) {
      tedarikciAlislari[a.cariId] = (tedarikciAlislari[a.cariId] ?? 0) + a.genelToplam;
    }
    var siraliTedarikciler = tedarikciAlislari.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Ürün bazlı gruplama
    Map<String, int> urunAlisMiktarlari = {};
    for (var d in _detaylar) {
      urunAlisMiktarlari[d.urunAdi] = (urunAlisMiktarlari[d.urunAdi] ?? 0) + d.miktar;
    }
    var siraliUrunler = urunAlisMiktarlari.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Alış Raporları', style: TextStyle(color: Colors.black)),
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
                        // Özet Kartı
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Toplam Alım', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('₺${toplamAlis.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Tedarikçi Bazlı Rapor
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tedarikçi Alımları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Divider(),
                                if (siraliTedarikciler.isEmpty) const Text('Veri yok') else ...siraliTedarikciler.map((e) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_cariAdiGetir(e.key), style: const TextStyle(fontWeight: FontWeight.w500)),
                                      Text('₺${e.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Ürün Bazlı Rapor
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('En Çok Alınan Ürünler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Divider(),
                                if (siraliUrunler.isEmpty) const Text('Veri yok') else ...siraliUrunler.take(10).map((e) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
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
}
