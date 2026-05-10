import 'package:flutter/material.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/services/rapor_service.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';

class CariRaporlariPage extends StatefulWidget {
  const CariRaporlariPage({super.key});

  @override
  State<CariRaporlariPage> createState() => _CariRaporlariPageState();
}

class _CariRaporlariPageState extends State<CariRaporlariPage> {
  final RaporService _raporService = RaporService();
  
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
      _cariler = await _raporService.getCariler();
    } catch (e) {
      debugPrint('Cari Rapor Hatasi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _ekstreGoster(Cari cari) async {
    showDialog(
      context: context,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    
    final baslangic = DateTime.now().subtract(const Duration(days: 365));
    final bitis = DateTime.now();
    final hareketler = await _raporService.getCariHareketler(cari.id!, baslangic, bitis);
    
    if (!mounted) return;
    Navigator.pop(context); // loading kapat
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('${cari.firmaAdi} Ekstresi', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: hareketler.isEmpty
                      ? const Center(child: Text('Hareket bulunamadı.'))
                      : ListView.separated(
                          controller: controller,
                          itemCount: hareketler.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final h = hareketler[index];
                            final isAlis = h.islemTipi.contains('Alış');
                            // Bakiye simülasyonu (gerçekte kümülatif olmalı ama UI için tutar ve tip gösteriyoruz)
                            return ListTile(
                              title: Text(h.islemTipi),
                              subtitle: Text('${h.tarih.day}.${h.tarih.month}.${h.tarih.year} - ${h.aciklama}'),
                              trailing: Text(
                                '${isAlis ? "-" : "+"}₺${h.tutar.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: isAlis ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final borclular = _cariler.where((c) => c.bakiye > 0).toList()..sort((a, b) => b.bakiye.compareTo(a.bakiye));
    final alacaklilar = _cariler.where((c) => c.bakiye < 0).toList()..sort((a, b) => a.bakiye.compareTo(b.bakiye));
    
    double toplamAlacak = borclular.fold(0, (sum, c) => sum + c.bakiye); // Bizim alacağımız (Müşteri Borcu)
    double toplamBorc = alacaklilar.fold(0, (sum, c) => sum + c.bakiye.abs()); // Bizim borcumuz (Tedarikçi Alacağı)

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: HesapixColors.bg,
        appBar: AppBar(
          title: const Text('Cari Hesap Raporları', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            labelColor: HesapixColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: HesapixColors.primary,
            tabs: [
              Tab(text: 'Borçlu Cariler (Alacağımız)'),
              Tab(text: 'Alacaklı Cariler (Borcumuz)'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Borçlu Cariler Sekmesi
                  _CariListesi(cariler: borclular, toplamTutar: toplamAlacak, isBorclu: true, onCariTap: _ekstreGoster),
                  // Alacaklı Cariler Sekmesi
                  _CariListesi(cariler: alacaklilar, toplamTutar: toplamBorc, isBorclu: false, onCariTap: _ekstreGoster),
                ],
              ),
      ),
    );
  }
}

class _CariListesi extends StatelessWidget {
  final List<Cari> cariler;
  final double toplamTutar;
  final bool isBorclu;
  final Function(Cari) onCariTap;

  const _CariListesi({required this.cariler, required this.toplamTutar, required this.isBorclu, required this.onCariTap});

  @override
  Widget build(BuildContext context) {
    final color = isBorclu ? Colors.green : Colors.red;
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(isBorclu ? 'Toplam Alacağımız' : 'Toplam Borcumuz', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('₺${toplamTutar.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: cariler.isEmpty
              ? const Center(child: Text('Kayıt bulunamadı.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cariler.length,
                  itemBuilder: (context, index) {
                    final c = cariler[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(Icons.business, color: color),
                        ),
                        title: Text(c.firmaAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(c.cariKodu),
                        trailing: Text('₺${c.bakiye.abs().toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                        onTap: () => onCariTap(c),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
