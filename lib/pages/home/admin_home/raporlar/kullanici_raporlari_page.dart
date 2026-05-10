import 'package:flutter/material.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/services/rapor_service.dart';
import 'package:hesapix_app/models/satis_model.dart';
import 'package:hesapix_app/models/app_user_model.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';

class KullaniciRaporlariPage extends StatefulWidget {
  const KullaniciRaporlariPage({super.key});

  @override
  State<KullaniciRaporlariPage> createState() => _KullaniciRaporlariPageState();
}

class _KullaniciRaporlariPageState extends State<KullaniciRaporlariPage> {
  final RaporService _raporService = RaporService();
  
  DateTime _baslangic = DateTime.now().subtract(const Duration(days: 30));
  DateTime _bitis = DateTime.now();
  
  List<Satis> _satislar = [];
  List<AppUserModel> _kasiyerler = [];
  List<CariHareket> _tahsilatlar = [];
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
      _kasiyerler = await _raporService.getKasiyerler();
      _tahsilatlar = await _raporService.getTahsilatOdemeHareketleri(_baslangic, _bitis);
    } catch (e) {
      debugPrint('Kullanıcı Rapor Hatasi: $e');
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

  String _kasiyerAdiBul(String id) {
    try {
      if (id.isEmpty) return 'Sistem/Admin';
      final k = _kasiyerler.firstWhere((x) => x.id == id);
      return k.adSoyad.isNotEmpty ? k.adSoyad : k.email;
    } catch (e) {
      // Eğer Kasiyer modelinde yoksa, muhtemelen AppUserModel (Admin) üzerinden yapılmıştır.
      return 'Sistem/Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kasiyer bazlı satış gruplaması
    Map<String, Map<String, dynamic>> kasiyerSatis = {};
    for (var s in _satislar) {
      String kId = s.kasiyerId;
      if (!kasiyerSatis.containsKey(kId)) {
        kasiyerSatis[kId] = {'adet': 0, 'ciro': 0.0};
      }
      kasiyerSatis[kId]!['adet'] += 1;
      kasiyerSatis[kId]!['ciro'] += s.genelToplam;
    }
    
    var siraliSatislar = kasiyerSatis.entries.toList()..sort((a, b) => b.value['ciro'].compareTo(a.value['ciro']));

    // Tahsilat gruplaması (CariHareket tablosunda normalde kimin yaptığı tutulmuyorsa, bu kısım genel tahsilat sayılabilir. 
    // Eğer CariHareket tablosunda ileride kasiyerId tutulursa eklenebilir. Şu an varsayımsal gösterim eklendi)
    
    // Varsayım: İptal/İade verisi (CariHareket veya Satis içinde yoksa)
    double iptalEdilenTutar = 0.0; // Şimdilik 0

    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Kullanıcı (Personel) Raporları', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
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
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // A) Kullanıcı Bazlı Satış
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Kullanıcı Bazlı Satış Performansı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Divider(),
                                const Row(
                                  children: [
                                    Expanded(flex: 2, child: Text('Kullanıcı', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                                    Expanded(child: Text('Adet', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                                    Expanded(child: Text('Ciro', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (siraliSatislar.isEmpty) const Text('Veri bulunamadı.') else ...siraliSatislar.map((e) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 2, child: Text(_kasiyerAdiBul(e.key), style: const TextStyle(fontWeight: FontWeight.bold))),
                                        Expanded(child: Text('${e.value['adet']}', textAlign: TextAlign.right)),
                                        Expanded(child: Text('₺${(e.value['ciro'] as double).toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(color: HesapixColors.primary, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // B) Tahsilat / C) İade
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Toplam İptal/İade', style: TextStyle(color: Colors.grey)),
                                      const SizedBox(height: 8),
                                      Text('₺${iptalEdilenTutar.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      const Text('Altyapı kurulduğunda aktifleşecek', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
