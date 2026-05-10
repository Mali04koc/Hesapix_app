import 'package:flutter/material.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/services/rapor_service.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';

class TahsilatRaporlariPage extends StatefulWidget {
  const TahsilatRaporlariPage({super.key});

  @override
  State<TahsilatRaporlariPage> createState() => _TahsilatRaporlariPageState();
}

class _TahsilatRaporlariPageState extends State<TahsilatRaporlariPage> {
  final RaporService _raporService = RaporService();
  
  DateTime _baslangic = DateTime.now().subtract(const Duration(days: 30));
  DateTime _bitis = DateTime.now();
  
  List<CariHareket> _tahsilatlar = [];
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
      _tahsilatlar = await _raporService.getTahsilatOdemeHareketleri(_baslangic, _bitis);
      _cariler = await _raporService.getCariler();
    } catch (e) {
      debugPrint('Tahsilat Rapor Hatasi: $e');
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

  String _cariAdiBul(String cariId) {
    try {
      return _cariler.firstWhere((c) => c.id == cariId).firmaAdi;
    } catch (e) {
      return 'Bilinmeyen Cari';
    }
  }

  @override
  Widget build(BuildContext context) {
    double toplamTahsilat = 0.0;
    double toplamOdeme = 0.0;

    for (var h in _tahsilatlar) {
      if (h.islemTipi.toLowerCase().contains('tahsilat') || h.aciklama.toLowerCase().contains('tahsilat')) {
        toplamTahsilat += h.tutar;
      } else {
        toplamOdeme += h.tutar;
      }
    }

    // Geciken borçlar (Vadesi geçmiş borçlar - Açık hesaplar)
    // Şimdilik sadece bakiyesi 0'dan büyük olan (Bize borcu olan) carileri alıyoruz
    final borcluCariler = _cariler.where((c) => c.bakiye > 0).toList()..sort((a, b) => b.bakiye.compareTo(a.bakiye));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: HesapixColors.bg,
        appBar: AppBar(
          title: const Text('Tahsilat & Borç Raporları', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            labelColor: HesapixColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: HesapixColors.primary,
            tabs: [
              Tab(text: 'Tahsilatlar'),
              Tab(text: 'Açık Borçlar'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Sekme 1: Tahsilatlar
                  Column(
                    children: [
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
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
                                child: Column(
                                  children: [
                                    const Text('Toplam Tahsilat (Giren)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text('₺${toplamTahsilat.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.3))),
                                child: Column(
                                  children: [
                                    const Text('Toplam Ödeme (Çıkan)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text('₺${toplamOdeme.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _tahsilatlar.isEmpty
                            ? const Center(child: Text('Belirtilen tarihte tahsilat kaydı yok.'))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _tahsilatlar.length,
                                itemBuilder: (context, index) {
                                  final h = _tahsilatlar[index];
                                  final isTahsilat = h.islemTipi.toLowerCase().contains('tahsilat') || h.aciklama.toLowerCase().contains('tahsilat');
                                  return Card(
                                    child: ListTile(
                                      leading: Icon(isTahsilat ? Icons.arrow_downward : Icons.arrow_upward, color: isTahsilat ? Colors.green : Colors.red),
                                      title: Text(_cariAdiBul(h.cariId), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${h.tarih.day}.${h.tarih.month}.${h.tarih.year} - ${h.aciklama}'),
                                      trailing: Text('₺${h.tutar.toStringAsFixed(2)}', style: TextStyle(color: isTahsilat ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                  
                  // Sekme 2: Açık Borçlar (Vadesi Geçmiş)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        width: double.infinity,
                        child: const Text('Ödeme Bekleyen Alacaklarımız (Müşteri Borçları)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                      ),
                      Expanded(
                        child: borcluCariler.isEmpty
                            ? const Center(child: Text('Açık borç bulunmuyor.'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: borcluCariler.length,
                                itemBuilder: (context, index) {
                                  final c = borcluCariler[index];
                                  // Vade süresi simülasyonu (Son işlem tarihinden bu yana geçen süre)
                                  int gecikmeGun = 0;
                                  if (c.sonIslemTarihi != null) {
                                    gecikmeGun = DateTime.now().difference(c.sonIslemTarihi!).inDays;
                                  }
                                  return Card(
                                    child: ListTile(
                                      title: Text(c.firmaAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(gecikmeGun > 30 ? '⚠ $gecikmeGun Gündür Açık!' : 'Son İşlem: $gecikmeGun gün önce', style: TextStyle(color: gecikmeGun > 30 ? Colors.red : Colors.grey)),
                                      trailing: Text('₺${c.bakiye.toStringAsFixed(2)}', style: const TextStyle(color: HesapixColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
