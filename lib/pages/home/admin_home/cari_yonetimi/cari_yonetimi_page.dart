import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';
import 'package:hesapix_app/services/cari_service.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/pages/home/admin_home/cari_yonetimi/dialogs/cari_dialog.dart';
import 'package:hesapix_app/pages/home/admin_home/cari_yonetimi/dialogs/cari_hareket_dialog.dart';

class CariYonetimiPage extends StatefulWidget {
  const CariYonetimiPage({super.key});

  @override
  State<CariYonetimiPage> createState() => _CariYonetimiPageState();
}

class _CariYonetimiPageState extends State<CariYonetimiPage> {
  final CariService _cariService = CariService();
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  late Stream<List<Cari>> _carilerStream;

  @override
  void initState() {
    super.initState();
    _carilerStream = _cariService.getCariler();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? HesapixColors.danger : HesapixColors.primary,
      ),
    );
  }

  Future<void> _cariEkleDialog() async {
    await showDialog(
      context: context,
      builder: (context) => CariDialog(
        onSubmit: (data) async {
          await _cariService.addCari(data);
          _snack('Cari başarıyla eklendi.');
        },
      ),
    );
  }

  Future<void> _cariDuzenleDialog(Cari c) async {
    await showDialog(
      context: context,
      builder: (context) => CariDialog(
        existingCari: c,
        onSubmit: (data) async {
          await _cariService.updateCari(data);
          _snack('Cari güncellendi.');
        },
      ),
    );
  }

  Future<void> _cariSilDialog(Cari c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cari Silinecek'),
        content: Text('${c.firmaAdi} isimli cariyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Sil', style: TextStyle(color: HesapixColors.danger))
          ),
        ],
      ),
    );
    if (confirm == true && c.id != null) {
      await _cariService.deleteCari(c.id!);
      _snack('Cari silindi.');
    }
  }

  Future<void> _hareketEkleDialog(String cariId) async {
    await showDialog(
      context: context,
      builder: (context) => CariHareketDialog(
        cariId: cariId,
        onSubmit: (hareket) async {
          await _cariService.addHareket(hareket);
          _snack('İşlem kaydedildi.');
        },
      ),
    );
  }

  void _showCariDetayDialog(Cari c) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(c.firmaAdi, style: const TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Vergi No:', c.vergiNo.isNotEmpty ? c.vergiNo : '-'),
                _detailRow('Bakiye:', '₺${c.bakiye.toStringAsFixed(2)}'),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('İşlem Hareketleri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('İşlem Ekle'),
                      onPressed: () => _hareketEkleDialog(c.id!),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<CariHareket>>(
                    stream: _cariService.getHareketler(c.id!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final hareketler = snapshot.data ?? [];
                      if (hareketler.isEmpty) {
                        return const Center(child: Text("Henüz işlem hareketi yok."));
                      }
                      return ListView.builder(
                        itemCount: hareketler.length,
                        itemBuilder: (context, index) {
                          final h = hareketler[index];
                          final isPozitif = h.islemTipi == 'SATIS' || h.islemTipi == 'ODEME_YAP';
                          
                          String islemAdi(String tip) {
                            switch (tip) {
                              case 'SATIS': return 'Satış Faturası';
                              case 'ALIS': return 'Alış Faturası';
                              case 'ODEME_AL': return 'Ödeme Alındı';
                              case 'ODEME_YAP': return 'Ödeme Yapıldı';
                              default: return tip;
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.grey.shade50,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: ListTile(
                              title: Text(islemAdi(h.islemTipi), style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm').format(h.tarih)}\n${h.aciklama}'),
                              isThreeLine: true,
                              trailing: Text(
                                '${isPozitif ? '+' : '-'}₺${h.tutar.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPozitif ? HesapixColors.success : HesapixColors.danger
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Cari Yönetimi', style: TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: HesapixColors.primary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Firma Adı veya Vergi No ile Ara',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Cari>>(
              stream: _carilerStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final cariler = snapshot.data ?? [];
                
                final filteredCariler = cariler.where((c) {
                  final query = _searchQuery.toLowerCase();
                  return c.firmaAdi.toLowerCase().contains(query) ||
                         c.vergiNo.toLowerCase().contains(query);
                }).toList();

                if (filteredCariler.isEmpty) {
                  return const Center(child: Text("Sonuç bulunamadı."));
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredCariler.length,
                  itemBuilder: (context, index) {
                    final c = filteredCariler[index];
                    Widget bakiyeWidget;
                    if (c.bakiye > 0) {
                      bakiyeWidget = Text('Alacak: ₺${c.bakiye.toStringAsFixed(2)}', style: const TextStyle(color: HesapixColors.success, fontWeight: FontWeight.bold));
                    } else if (c.bakiye < 0) {
                      bakiyeWidget = Text('Verecek: ₺${c.bakiye.abs().toStringAsFixed(2)}', style: const TextStyle(color: HesapixColors.danger, fontWeight: FontWeight.bold));
                    } else {
                      bakiyeWidget = const Text('0 ₺', style: TextStyle(fontWeight: FontWeight.bold));
                    }
                    
                    final tarihStr = c.sonIslemTarihi != null ? DateFormat('dd/MM/yyyy').format(c.sonIslemTarihi!) : '-';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () => _showCariDetayDialog(c),
                        leading: CircleAvatar(
                          backgroundColor: HesapixColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.business, color: HesapixColors.primary),
                        ),
                        title: Text('${c.cariKodu} - ${c.firmaAdi}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Son İşlem: $tarihStr'),
                            bakiyeWidget,
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              onPressed: () => _cariDuzenleDialog(c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: HesapixColors.danger),
                              onPressed: () => _cariSilDialog(c),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _cariEkleDialog,
        backgroundColor: HesapixColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
