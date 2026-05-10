import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/services/satis_provider.dart';
import 'package:hesapix_app/services/satis_service.dart';
import 'package:hesapix_app/services/pdf_service.dart';
import 'package:hesapix_app/services/urun_service.dart';
import 'package:hesapix_app/services/cari_service.dart';
import 'package:hesapix_app/models/urun_model.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/pages/home/admin_home/fiyat_gor/fiyat_gor_page.dart'; // Barcode okuyucu

class SatisFaturasiPage extends StatefulWidget {
  const SatisFaturasiPage({super.key});

  @override
  State<SatisFaturasiPage> createState() => _SatisFaturasiPageState();
}

class _SatisFaturasiPageState extends State<SatisFaturasiPage> {
  final TextEditingController _aramaCtrl = TextEditingController();
  final UrunService _urunService = UrunService();
  final CariService _cariService = CariService();
  final SatisService _satisService = SatisService();
  
  Cari? _seciliCari;
  bool _isProcessing = false;

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? HesapixColors.danger : HesapixColors.success,
      ),
    );
  }

  Future<void> _barkodOkut() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );
    if (code != null && code.isNotEmpty) {
      _urunAraVeEkle(code);
    }
  }

  Future<void> _urunAraVeEkle(String query) async {
    if (query.isEmpty) return;
    try {
      final urunler = await _urunService.urunAra(query);
      if (urunler.isNotEmpty) {
        final tamEslesen = urunler.firstWhere(
          (u) => u.barkod == query || u.urunKodu == query,
          orElse: () => urunler.first,
        );
        
        if (tamEslesen.stok > 0) {
           Provider.of<SatisProvider>(context, listen: false).sepeteEkle(tamEslesen);
           _snack('${tamEslesen.isim} eklendi.');
        } else {
           _snack('Stok yetersiz!', error: true);
        }
      } else {
        _snack('Ürün bulunamadı!', error: true);
      }
    } catch (e) {
      _snack('Hata: $e', error: true);
    }
    _aramaCtrl.clear();
  }

  Future<void> _cariSecDialog() async {
    final cariler = await _cariService.getCariler().first;
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cari Seçin'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: cariler.length,
              itemBuilder: (context, index) {
                final c = cariler[index];
                return ListTile(
                  title: Text('${c.cariKodu} - ${c.firmaAdi}'),
                  subtitle: Text('Bakiye: ₺${c.bakiye.toStringAsFixed(2)}'),
                  onTap: () {
                    setState(() => _seciliCari = c);
                    Provider.of<SatisProvider>(context, listen: false).setCariId(c.id ?? '');
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _satisiTamamla() async {
    final provider = Provider.of<SatisProvider>(context, listen: false);
    
    if (provider.sepet.isEmpty) {
      _snack('Sepet boş olamaz!', error: true);
      return;
    }
    
    if (provider.odemeTuru == 'Açık Hesap' && _seciliCari == null) {
      _snack('Açık hesap işleminde cari seçimi zorunludur!', error: true);
      return;
    }

    setState(() => _isProcessing = true);
    
    try {
      final sepetKopya = List.of(provider.sepet); // Sepeti temizlemeden önce kopya alalım
      final satis = await _satisService.satisYap(
        cariId: _seciliCari?.id ?? 'PERAKENDE_CARI_ID', // Ya da boş
        araToplam: provider.araToplam,
        kdvToplam: provider.kdvToplam,
        iskonto: provider.iskonto,
        genelToplam: provider.genelToplam,
        odemeTuru: provider.odemeTuru,
        kasiyerId: '1', // Şu anlık sabit, ileride session'dan alınabilir
        sepet: provider.sepet,
      );
      
      _snack('Satış başarıyla tamamlandı!');
      
      // PDF Fiş/Fatura Gösterme Dialogu
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Satış Başarılı'),
            content: const Text('Satış kaydedildi. Fiş/Fatura yazdırmak veya paylaşmak ister misiniz?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Kapat
                  provider.sepetiTemizle();
                  setState(() => _seciliCari = null);
                },
                child: const Text('Hayır, Kapat', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context); // Dialogu kapat
                  try {
                    final pdfBytes = await PdfService.generateSatisFaturasiPdf(
                      satis: satis,
                      detaylar: sepetKopya,
                      cariIsim: _seciliCari?.firmaAdi ?? 'Perakende Müşteri',
                    );
                    await PdfService.sharePdf(pdfBytes, 'Fatura_${satis.faturaNo}');
                  } catch (e) {
                     _snack('PDF oluşturulurken hata: $e', error: true);
                  } finally {
                    provider.sepetiTemizle();
                    setState(() => _seciliCari = null);
                  }
                },
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text('PDF Paylaş / Yazdır', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: HesapixColors.primary),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SatisProvider>(context);

    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Satış Faturası', style: TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: HesapixColors.primary),
      ),
      body: _isProcessing 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // A) Üst Alan (Header)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tarih: ${DateTime.now().day.toString().padLeft(2,'0')}.${DateTime.now().month.toString().padLeft(2,'0')}.${DateTime.now().year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: provider.odemeTuru,
                          items: const [
                            DropdownMenuItem(value: 'Nakit', child: Text('Nakit')),
                            DropdownMenuItem(value: 'Kart', child: Text('Kart')),
                            DropdownMenuItem(value: 'Açık Hesap', child: Text('Açık Hesap')),
                          ],
                          onChanged: (val) {
                            if (val != null) provider.setOdemeTuru(val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _cariSecDialog,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300)
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _seciliCari != null ? _seciliCari!.firmaAdi : 'Cari Seç (Açık hesap için zorunlu)',
                              style: TextStyle(color: _seciliCari != null ? Colors.black87 : Colors.grey.shade600, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.person_search, color: HesapixColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // B) Ürün Arama Alanı
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Autocomplete<Urun>(
                        optionsBuilder: (TextEditingValue textEditingValue) async {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Urun>.empty();
                          }
                          try {
                            final products = await _urunService.urunAra(textEditingValue.text);
                            return products;
                          } catch (e) {
                            return const Iterable<Urun>.empty();
                          }
                        },
                        displayStringForOption: (Urun option) => option.isim,
                        onSelected: (Urun selection) {
                          if (selection.stok > 0) {
                            Provider.of<SatisProvider>(context, listen: false).sepeteEkle(selection);
                            _snack('${selection.isim} eklendi.');
                          } else {
                            _snack('Stok yetersiz!', error: true);
                          }
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Barkod, Ürün Adı veya Kodu (Yazmaya başlayın)',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onSubmitted: (value) async {
                              await _urunAraVeEkle(value);
                              controller.clear();
                            },
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 250),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      title: Text(option.isim, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('Barkod: ${option.barkod} | Stok: ${option.stok} | Fiyat: ₺${option.satisFiyat.toStringAsFixed(2)}'),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(color: HesapixColors.accent, borderRadius: BorderRadius.circular(12)),
                      child: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                        onPressed: _barkodOkut,
                      ),
                    ),
                  ],
                ),
              ),

              // C) Sepet Alanı
              Expanded(
                child: provider.sepet.isEmpty
                  ? const Center(child: Text('Sepet Boş', style: TextStyle(fontSize: 18, color: Colors.grey)))
                  : ListView.builder(
                      itemCount: provider.sepet.length,
                      itemBuilder: (context, index) {
                        final item = provider.sepet[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            title: Text(item.urunAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('₺${item.birimFiyat.toStringAsFixed(2)} x ${item.miktar}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () => provider.miktarGuncelle(item.urunId, item.miktar - 1),
                                ),
                                Text('${item.miktar}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                  onPressed: () => provider.miktarGuncelle(item.urunId, item.miktar + 1),
                                ),
                                const SizedBox(width: 8),
                                Text('₺${item.toplam.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: HesapixColors.primary)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),

              // D) Alt Toplam ve Satış Butonu
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ara Toplam:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text('₺${provider.araToplam.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('KDV Toplam:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text('₺${provider.kdvToplam.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Genel Toplam:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('₺${provider.genelToplam.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: HesapixColors.success)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HesapixColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _satisiTamamla,
                        child: const Text('Satışı Tamamla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
