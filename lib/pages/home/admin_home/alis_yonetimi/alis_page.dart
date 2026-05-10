import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/services/alis_provider.dart';
import 'package:hesapix_app/services/alis_service.dart';
import 'package:hesapix_app/services/pdf_service.dart';
import 'package:hesapix_app/services/urun_service.dart';
import 'package:hesapix_app/services/cari_service.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/urun_model.dart';
import 'package:hesapix_app/pages/home/admin_home/fiyat_gor/fiyat_gor_page.dart';

class AlisPage extends StatefulWidget {
  const AlisPage({super.key});

  @override
  State<AlisPage> createState() => _AlisPageState();
}

class _AlisPageState extends State<AlisPage> {
  final TextEditingController _aramaCtrl = TextEditingController();
  final UrunService _urunService = UrunService();
  final CariService _cariService = CariService();
  final AlisService _alisService = AlisService();
  
  Cari? _seciliTedarikci;
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
        
        Provider.of<AlisProvider>(context, listen: false).sepeteEkle(tamEslesen);
        _snack('${tamEslesen.isim} eklendi.');
      } else {
        _snack('Ürün bulunamadı!', error: true);
      }
    } catch (e) {
      _snack('Hata: $e', error: true);
    }
    _aramaCtrl.clear();
  }

  Future<void> _tedarikciSecDialog() async {
    final cariler = await _cariService.getCariler().first;
    // Sadece tedarikçi olanları filtrelemek istenirse burada yapılabilir:
    // final tedarikciler = cariler.where((c) => c.cariTipi == 'Tedarikçi').toList();
    // Şimdilik hepsi
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tedarikçi (Cari) Seçin'),
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
                    setState(() => _seciliTedarikci = c);
                    Provider.of<AlisProvider>(context, listen: false).setCariId(c.id ?? '');
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

  Future<void> _alisiTamamla() async {
    final provider = Provider.of<AlisProvider>(context, listen: false);
    
    if (provider.sepet.isEmpty) {
      _snack('Sepet boş olamaz!', error: true);
      return;
    }
    
    if (_seciliTedarikci == null) {
      _snack('Alış işleminde tedarikçi seçimi zorunludur!', error: true);
      return;
    }

    setState(() => _isProcessing = true);
    
    try {
      final sepetKopya = List.of(provider.sepet);
      final alis = await _alisService.alisYap(
        cariId: _seciliTedarikci!.id ?? '', 
        araToplam: provider.araToplam,
        kdvToplam: provider.kdvToplam,
        iskonto: provider.iskonto,
        genelToplam: provider.genelToplam,
        odemeTuru: provider.odemeTuru,
        kasiyerId: '1', 
        sepet: provider.sepet,
      );
      
      _snack('Alış Faturası başarıyla kaydedildi!');
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Alış Başarılı'),
            content: const Text('Alış faturası kaydedildi. Fiş/Fatura yazdırmak veya paylaşmak ister misiniz?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  provider.sepetiTemizle();
                  setState(() => _seciliTedarikci = null);
                },
                child: const Text('Hayır, Kapat', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final pdfBytes = await PdfService.generateAlisFaturasiPdf(
                      alis: alis,
                      detaylar: sepetKopya,
                      tedarikciIsim: _seciliTedarikci?.firmaAdi ?? 'Tedarikçi',
                    );
                    await PdfService.sharePdf(pdfBytes, 'AlisFaturasi_${alis.faturaNo}');
                  } catch (e) {
                     _snack('PDF oluşturulurken hata: $e', error: true);
                  } finally {
                    provider.sepetiTemizle();
                    setState(() => _seciliTedarikci = null);
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

  void _fiyatDuzenleDialog(String urunId, String urunAdi, double mevcutFiyat) {
    final TextEditingController fiyatCtrl = TextEditingController(text: mevcutFiyat.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('$urunAdi Alış Fiyatı'),
          content: TextField(
            controller: fiyatCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Yeni Fiyat (₺)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final yeni = double.tryParse(fiyatCtrl.text.replaceAll(',', '.'));
                if (yeni != null && yeni >= 0) {
                  Provider.of<AlisProvider>(context, listen: false).fiyatGuncelle(urunId, yeni);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AlisProvider>(context);

    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Alış Faturası (Tedarikçi)', style: TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
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
                            DropdownMenuItem(value: 'Açık Hesap', child: Text('Açık Hesap')),
                            DropdownMenuItem(value: 'Nakit', child: Text('Nakit')),
                            DropdownMenuItem(value: 'Kart', child: Text('Kart')),
                          ],
                          onChanged: (val) {
                            if (val != null) provider.setOdemeTuru(val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _tedarikciSecDialog,
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
                              _seciliTedarikci != null ? _seciliTedarikci!.firmaAdi : 'Tedarikçi Seç (Zorunlu)',
                              style: TextStyle(
                                color: _seciliTedarikci != null ? Colors.black87 : HesapixColors.danger, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            const Icon(Icons.business, color: HesapixColors.primary),
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
                          Provider.of<AlisProvider>(context, listen: false).sepeteEkle(selection);
                          _snack('${selection.isim} eklendi.');
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
                                      subtitle: Text('Barkod: ${option.barkod} | Stok: ${option.stok} | Maliyet: ₺${option.alisFiyat.toStringAsFixed(2)}'),
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
                  ? const Center(child: Text('Alış Sepeti Boş', style: TextStyle(fontSize: 18, color: Colors.grey)))
                  : ListView.builder(
                      itemCount: provider.sepet.length,
                      itemBuilder: (context, index) {
                        final item = provider.sepet[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(item.urunAdi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => provider.sepettenCikar(item.urunId),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Fiyat Değiştirme
                                    InkWell(
                                      onTap: () => _fiyatDuzenleDialog(item.urunId, item.urunAdi, item.birimFiyat),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            Text('₺${item.birimFiyat.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.edit, size: 14, color: Colors.orange),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Miktar Ayarlama
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                          onPressed: () => provider.miktarGuncelle(item.urunId, item.miktar - 1),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('${item.miktar}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                          onPressed: () => provider.miktarGuncelle(item.urunId, item.miktar + 1),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    // Satır Toplamı
                                    Text('₺${item.toplam.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: HesapixColors.primary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),

              // D) Alt Toplam ve Kaydet Butonu
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
                        onPressed: _alisiTamamla,
                        child: const Text('Alışı Kaydet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
