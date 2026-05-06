import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/siparis_model.dart';
import 'package:hesapix_app/services/siparis_service.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

class SatisFaturasiOdemePage extends StatefulWidget {
  final Cari cari;
  final List<Map<String, dynamic>> sepet;

  const SatisFaturasiOdemePage({super.key, required this.cari, required this.sepet});

  @override
  State<SatisFaturasiOdemePage> createState() => _SatisFaturasiOdemePageState();
}

class _SatisFaturasiOdemePageState extends State<SatisFaturasiOdemePage> {
  final SiparisService _siparisService = SiparisService();
  final TextEditingController _odenenCtrl = TextEditingController();
  
  double _toplamTutar = 0;
  String _odemeTipi = 'Nakit'; // Nakit, Kredi Kartı
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _toplamTutar = widget.sepet.fold(0, (sum, item) => sum + (item['toplam'] as double));
    _odenenCtrl.text = _toplamTutar.toStringAsFixed(2); // Varsayılan olarak tamamı ödendi
  }

  @override
  void dispose() {
    _odenenCtrl.dispose();
    super.dispose();
  }

  String _generateSiparisNo() {
    final random = Random();
    final number = 100000 + random.nextInt(900000); // 6 haneli rastgele sayı
    return 'SP-$number';
  }

  Future<void> _siparisTamamla() async {
    double odenen = double.tryParse(_odenenCtrl.text.trim()) ?? 0.0;
    if (odenen < 0 || odenen > _toplamTutar) {
      _snack('Geçersiz ödenen tutar. (0 ile $_toplamTutar arası olmalı)', error: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final siparisNo = _generateSiparisNo();
      
      // sepet modelini veritabanı formatına çevir
      final List<Map<String, dynamic>> dbSepet = widget.sepet.map((item) {
        final urun = item['urun'];
        return {
          'urun_doc_id': urun.id,
          'urun_ismi': urun.isim,
          'adet': item['adet'],
          'fiyat': item['fiyat'],
          'toplam': item['toplam'],
        };
      }).toList();

      final yeniSiparis = Siparis(
        siparisNo: siparisNo,
        cariId: widget.cari.id ?? '',
        cariAdi: widget.cari.firmaAdi,
        kasiyerId: 'Admin', // Normalde Auth user ID
        tarih: DateTime.now(),
        toplamTutar: _toplamTutar,
        odenenTutar: odenen,
        odemeTipi: _odemeTipi,
        sepet: dbSepet,
      );

      await _siparisService.addSiparis(yeniSiparis);
      
      _snack('Sipariş başarıyla oluşturuldu! Stoklar güncellendi.');
      
      // Başarılı olursa admin home page'e geri dönelim (tüm sayfa geçmişini silerek)
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), error: true);
      setState(() => _isLoading = false);
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? HesapixColors.danger : HesapixColors.success,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _urunCikar(int index) {
    setState(() {
      widget.sepet.removeAt(index);
      _toplamTutar = widget.sepet.fold(0, (sum, item) => sum + (item['toplam'] as double));
      _odenenCtrl.text = _toplamTutar.toStringAsFixed(2);
    });
    if (widget.sepet.isEmpty) {
      _snack('Sepet boşaldı.');
      Navigator.pop(context);
    }
  }

  void _adetDuzenle(int index) {
    int tempAdet = widget.sepet[index]['adet'];
    final urun = widget.sepet[index]['urun'];
    TextEditingController tempCtrl = TextEditingController(text: tempAdet.toString());
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${urun.isim}\nAdet Düzenle', textAlign: TextAlign.center),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (tempAdet > 1) {
                        setDialogState(() {
                          tempAdet--;
                          tempCtrl.text = tempAdet.toString();
                        });
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: HesapixColors.primary, size: 32),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: tempCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        int? parsed = int.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          if (parsed <= urun.stok) {
                            tempAdet = parsed;
                          } else {
                            _snack('Stokta yalnızca ${urun.stok} adet var!', error: true);
                            tempCtrl.text = urun.stok.toString();
                            tempAdet = urun.stok;
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (urun.stok > tempAdet) {
                        setDialogState(() {
                          tempAdet++;
                          tempCtrl.text = tempAdet.toString();
                        });
                      } else {
                        _snack('Stokta yalnızca ${urun.stok} adet var!', error: true);
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline, color: HesapixColors.primary, size: 32),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      widget.sepet[index]['adet'] = tempAdet;
                      widget.sepet[index]['toplam'] = widget.sepet[index]['fiyat'] * tempAdet;
                      _toplamTutar = widget.sepet.fold(0, (sum, item) => sum + (item['toplam'] as double));
                      _odenenCtrl.text = _toplamTutar.toStringAsFixed(2);
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: HesapixColors.primary, foregroundColor: Colors.white),
                  child: const Text('Güncelle'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    double odenen = double.tryParse(_odenenCtrl.text) ?? 0;
    double kalanBorc = _toplamTutar - odenen;
    if (kalanBorc < 0) kalanBorc = 0;

    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Ödeme Ekranı', style: TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: HesapixColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cari Bilgisi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cari Firma:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text(widget.cari.firmaAdi, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sepet Özeti
            const Text('Sepet Özeti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.sepet.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = widget.sepet[index];
                  final urun = item['urun'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(urun.isim, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${item['adet']} adet x ₺${item['fiyat']}', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Text('₺${item['toplam']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _adetDuzenle(index),
                          tooltip: 'Düzenle',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _urunCikar(index),
                          tooltip: 'Sepetten Çıkar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Toplam ve Ödeme Ayarları
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HesapixColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HesapixColors.primary.withOpacity(0.2), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Genel Toplam:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('₺${_toplamTutar.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: HesapixColors.primary)),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Ödeme Yöntemi:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Nakit'),
                          value: 'Nakit',
                          groupValue: _odemeTipi,
                          onChanged: (val) => setState(() => _odemeTipi = val!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Kredi Kartı'),
                          value: 'Kredi Kartı',
                          groupValue: _odemeTipi,
                          onChanged: (val) => setState(() => _odemeTipi = val!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Alınan Tutar:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _odenenCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixText: '₺ ',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _odenenCtrl.text = '0';
                          setState(() {});
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  if (kalanBorc > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: HesapixColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: HesapixColors.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cari hesaba borç olarak eklenecek tutar: ₺${kalanBorc.toStringAsFixed(2)}',
                              style: const TextStyle(color: HesapixColors.danger, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _siparisTamamla,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HesapixColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Siparişi Tamamla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
