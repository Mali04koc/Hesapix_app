import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/services/alis_provider.dart';
import 'package:hesapix_app/services/alis_service.dart';
import 'package:hesapix_app/services/pdf_service.dart';
import 'package:hesapix_app/core/database/service_locator.dart';
import 'package:hesapix_app/services/interfaces/i_urun_service.dart';
import 'package:hesapix_app/services/interfaces/i_cari_service.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/urun_model.dart';
import 'package:hesapix_app/models/alis_detay_model.dart';
import 'package:hesapix_app/pages/home/admin_home/fiyat_gor/fiyat_gor_page.dart';
import 'package:hesapix_app/pages/home/admin_home/pdf/pdf_preview_page.dart';
import 'package:hesapix_app/services/session_service.dart';

class AlisPage extends StatefulWidget {
  const AlisPage({super.key});

  @override
  State<AlisPage> createState() => _AlisPageState();
}

class _AlisPageState extends State<AlisPage> {
  final TextEditingController _aramaCtrl = TextEditingController();
  final TextEditingController _odenenCtrl = TextEditingController();
  final IUrunService _urunService = ServiceLocator.urunService;
  final ICariService _cariService = ServiceLocator.cariService;
  final AlisService _alisService = AlisService();
  
  Cari? _seciliTedarikci;
  bool _isOdenenEdited = false; // Kullanıcı elle değiştirdi mi?

  @override
  void dispose() {
    _aramaCtrl.dispose();
    _odenenCtrl.dispose();
    super.dispose();
  }
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
    final allCariler = await _cariService.getCariler().first;
    // Kod: 111 olan genel müşteriyi alış kısmında gösterme
    final cariler = allCariler.where((c) => c.cariKodu != '111').toList();
    
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
      double odenen = double.tryParse(_odenenCtrl.text.replaceAll(',', '.')) ?? 0.0;
      
      // Cari 111 Kontrolü (Kısmi ödeme yasak)
      if (_seciliTedarikci?.cariKodu == '111' && odenen < provider.genelToplam) {
        _snack('Genel müşteri (111) için kısmi ödeme yapılamaz. Lütfen tutarın tamamını girin.', error: true);
        setState(() => _isProcessing = false);
        return;
      }

      if (odenen > provider.genelToplam) odenen = provider.genelToplam;
      
      final currentUser = await SessionService().read();
      final kasiyerAdi = currentUser?.username ?? 'Admin';

      final alis = await _alisService.alisYap(
        cariId: _seciliTedarikci!.id ?? '', 
        araToplam: provider.araToplam,
        kdvToplam: provider.kdvToplam,
        iskonto: provider.iskonto,
        genelToplam: provider.genelToplam,
        odemeTuru: provider.odemeTuru,
        odenenTutar: odenen,
        kasiyerId: kasiyerAdi, 
        sepet: provider.sepet,
      );
      
      _snack('Alış Faturası başarıyla kaydedildi!');
      
      if (mounted) {
        _showBasariDialog(alis, sepetKopya);
      }
      
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showBasariDialog(dynamic alis, List<dynamic> detaylar) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: HesapixColors.success, size: 60),
            SizedBox(height: 16),
            Text('Alış Gerçekleşti', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Alış faturası başarıyla kaydedildi ve stoklar güncellendi.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final pdfData = await PdfService.generateAlisFaturasiPdf(
                      alis: alis,
                      detaylar: detaylar.cast<AlisDetay>().toList(),
                      tedarikci: _seciliTedarikci!,
                    );
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfPreviewPage(
                            pdfData: pdfData,
                            title: 'Alış Faturası Önizleme',
                            filename: 'hesapix_${alis.faturaNo}',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Faturayı Görüntüle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HesapixColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Provider.of<AlisProvider>(context, listen: false).sepetiTemizle();
                  setState(() => _seciliTedarikci = null);
                  Navigator.of(context).pop(); // Dialogu kapat
                },
                child: const Text('Tamam'),
              ),
            ],
          ),
        ],
      ),
    );
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

  void _adetDuzenleDialog(String urunId, String urunAdi, int mevcutAdet) {
    int tempAdet = mevcutAdet;
    final TextEditingController tempCtrl = TextEditingController(text: tempAdet.toString());
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('$urunAdi\nAdet Düzenle', textAlign: TextAlign.center),
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
                          tempAdet = parsed;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setDialogState(() {
                        tempAdet++;
                        tempCtrl.text = tempAdet.toString();
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline, color: HesapixColors.primary, size: 32),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () {
                    Provider.of<AlisProvider>(context, listen: false).miktarGuncelle(urunId, tempAdet);
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
    final provider = Provider.of<AlisProvider>(context);

    // Otomatik tutar doldurma (Kullanıcı elle değiştirmediyse toplamla senkronize tut)
    if (!_isOdenenEdited && provider.genelToplam > 0) {
      String currentTotal = provider.genelToplam.toStringAsFixed(2);
      if (_odenenCtrl.text != currentTotal) {
        _odenenCtrl.text = currentTotal;
      }
    }

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
                                        InkWell(
                                          onTap: () => _adetDuzenleDialog(item.urunId, item.urunAdi, item.miktar),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                                            child: Text('${item.miktar}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          ),
                                        ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ödenen Tutar:', style: TextStyle(fontWeight: FontWeight.w600)),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _odenenCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              isDense: true,
                              prefixText: '₺ ',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _isOdenenEdited = true;
                                if (val.isEmpty) _isOdenenEdited = false; // Silinirse tekrar otomatiğe bağla
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        double odenen = double.tryParse(_odenenCtrl.text.replaceAll(',', '.')) ?? 0;
                        double kalanBorc = provider.genelToplam - odenen;
                        if (kalanBorc < 0) kalanBorc = 0;
                        
                        if (kalanBorc > 0) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: HesapixColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: HesapixColors.danger, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Cari hesaba borç olarak eklenecek: ₺${kalanBorc.toStringAsFixed(2)}',
                                    style: const TextStyle(color: HesapixColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
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
                        child: const Text('Alışı Onayla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
