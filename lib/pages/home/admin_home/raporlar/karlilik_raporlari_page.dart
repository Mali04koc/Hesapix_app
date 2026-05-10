import 'package:flutter/material.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/services/rapor_service.dart';
import 'package:hesapix_app/models/satis_model.dart';
import 'package:hesapix_app/models/satis_detay_model.dart';
import 'package:hesapix_app/models/urun_model.dart';
import 'package:hesapix_app/models/cari_model.dart';

class KarlilikRaporlariPage extends StatefulWidget {
  const KarlilikRaporlariPage({super.key});

  @override
  State<KarlilikRaporlariPage> createState() => _KarlilikRaporlariPageState();
}

class _KarlilikRaporlariPageState extends State<KarlilikRaporlariPage> {
  final RaporService _raporService = RaporService();
  
  DateTime _baslangic = DateTime.now().subtract(const Duration(days: 30));
  DateTime _bitis = DateTime.now();
  
  List<Satis> _satislar = [];
  List<SatisDetay> _detaylar = [];
  List<Urun> _urunler = [];
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
      _satislar = await _raporService.getSatislar(_baslangic, _bitis);
      _detaylar = await _raporService.getSatisDetaylari(_baslangic, _bitis);
      _urunler = await _raporService.getTumUrunler();
      _cariler = await _raporService.getCariler();
    } catch (e) {
      debugPrint('Karlilik Rapor Hatasi: $e');
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

  double _urunMaliyetiniBul(String urunId) {
    try {
      final u = _urunler.firstWhere((x) => x.id == urunId);
      return u.alisFiyat ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  String _cariAdiBul(String cariId) {
    try {
      if (cariId.isEmpty) return 'Perakende Müşteri';
      return _cariler.firstWhere((c) => c.id == cariId).firmaAdi;
    } catch (e) {
      return 'Bilinmeyen Cari';
    }
  }

  @override
  Widget build(BuildContext context) {
    double toplamCiro = _satislar.fold(0, (sum, item) => sum + item.genelToplam);
    double toplamMaliyet = 0;
    
    // Ürün bazlı Karlılık Map'i
    Map<String, Map<String, dynamic>> urunKarlari = {};
    
    for (var d in _detaylar) {
      double urunAlisFiyati = _urunMaliyetiniBul(d.urunId);
      double satirMaliyeti = d.miktar * urunAlisFiyati;
      toplamMaliyet += satirMaliyeti;
      
      double satirSatisTutari = d.toplam;
      double satirKari = satirSatisTutari - satirMaliyeti;

      if (!urunKarlari.containsKey(d.urunAdi)) {
        urunKarlari[d.urunAdi] = {'satisTutar': 0.0, 'maliyet': 0.0, 'kar': 0.0};
      }
      urunKarlari[d.urunAdi]!['satisTutar'] += satirSatisTutari;
      urunKarlari[d.urunAdi]!['maliyet'] += satirMaliyeti;
      urunKarlari[d.urunAdi]!['kar'] += satirKari;
    }

    double netKar = toplamCiro - toplamMaliyet;
    double karOrani = toplamCiro > 0 ? (netKar / toplamCiro) * 100 : 0;

    // Cari bazlı Kârlılık Map'i (Fatura üzerinden kabaca)
    // Tam doğru analiz için faturadaki detayların maliyeti toplanmalı
    Map<String, double> cariSatislari = {};
    for(var s in _satislar) {
       cariSatislari[s.cariId] = (cariSatislari[s.cariId] ?? 0.0) + s.genelToplam;
    }

    var siraliUrunler = urunKarlari.entries.toList()..sort((a, b) => b.value['kar'].compareTo(a.value['kar']));
    var siraliCariler = cariSatislari.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Kârlılık Raporları', style: TextStyle(color: Colors.black)),
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
                        // A) Genel Kârlılık Kartları
                        Row(
                          children: [
                            _kutu('Ciro', '₺${toplamCiro.toStringAsFixed(2)}', Colors.blue),
                            const SizedBox(width: 8),
                            _kutu('Maliyet', '₺${toplamMaliyet.toStringAsFixed(2)}', Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _kutu('Net Kâr', '₺${netKar.toStringAsFixed(2)}', netKar >= 0 ? Colors.green : Colors.red),
                            const SizedBox(width: 8),
                            _kutu('Kâr Oranı', '%${karOrani.toStringAsFixed(2)}', netKar >= 0 ? Colors.green : Colors.red),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // B) Ürün Bazlı Kârlılık
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ürün Bazlı Kârlılık (Top 10)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Divider(),
                                const Row(
                                  children: [
                                    Expanded(flex: 2, child: Text('Ürün', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(child: Text('Kâr', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                                    Expanded(child: Text('Oran', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...siraliUrunler.take(10).map((e) {
                                  double uSatis = e.value['satisTutar'];
                                  double uKar = e.value['kar'];
                                  double uOran = uSatis > 0 ? (uKar / uSatis) * 100 : 0;
                                  Color kColor = uKar >= 0 ? Colors.green : Colors.red;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 2, child: Text(e.key, overflow: TextOverflow.ellipsis)),
                                        Expanded(child: Text('₺${uKar.toStringAsFixed(2)}', textAlign: TextAlign.right, style: TextStyle(color: kColor, fontWeight: FontWeight.bold))),
                                        Expanded(child: Text('%${uOran.toStringAsFixed(1)}', textAlign: TextAlign.right, style: TextStyle(color: kColor, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // C) Cari Bazlı Karlılık Özeti
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('En Çok Ciro Getiren Cariler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Divider(),
                                ...siraliCariler.take(5).map((e) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(_cariAdiBul(e.key))),
                                      Text('₺${e.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
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

  Widget _kutu(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
