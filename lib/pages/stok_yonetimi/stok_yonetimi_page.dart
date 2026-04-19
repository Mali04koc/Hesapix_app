import 'package:flutter/material.dart';
import 'package:hesapix_app/models/kategori_model.dart';
import 'package:hesapix_app/models/urun_model.dart';
import 'package:hesapix_app/services/kategori_service.dart';
import 'package:hesapix_app/services/urun_service.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/pages/stok_yonetimi/dialogs/kategori_dialog.dart';
import 'package:hesapix_app/pages/stok_yonetimi/dialogs/urun_dialog.dart';

class StokYonetimiPage extends StatefulWidget {
  const StokYonetimiPage({super.key});

  @override
  State<StokYonetimiPage> createState() => _StokYonetimiPageState();
}

class _StokYonetimiPageState extends State<StokYonetimiPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final KategoriService _kategoriService = KategoriService();
  final UrunService _urunService = UrunService();

  List<Kategori> _kategoriler = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _kategoriService.getKategoriler().listen((data) {
      if (mounted) setState(() => _kategoriler = data);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<void> _kategoriEkleDialog() async {
    await showDialog(
      context: context,
      builder: (context) => KategoriDialog(
        onSubmit: (isim) async {
          final yeniKategori = Kategori(kategoriId: 0, isim: isim, cesit: 0, adet: 0);
          await _kategoriService.addKategori(yeniKategori);
        },
      ),
    );
  }

  Future<void> _kategoriDuzenleDialog(Kategori k) async {
    await showDialog(
      context: context,
      builder: (context) => KategoriDialog(
        existingKategori: k,
        onSubmit: (isim) async {
          final guncelKategori = Kategori(
            id: k.id,
            kategoriId: k.kategoriId,
            isim: isim,
            cesit: k.cesit,
            adet: k.adet,
          );
          await _kategoriService.updateKategori(guncelKategori);
        },
      ),
    );
  }

  Future<void> _urunEkleDialog() async {
    if (_kategoriler.isEmpty) {
      _snack("Önce bir kategori eklemelisiniz.", isError: true);
      return;
    }
    await showDialog(
      context: context,
      builder: (context) => UrunDialog(
        kategoriler: _kategoriler,
        onSubmit: (data) async {
          final yeniUrun = Urun(
            urunId: 0,
            isim: data.isim,
            alisFiyat: data.alisFiyat,
            satisFiyat: data.satisFiyat,
            stok: data.stok,
            barkod: data.barkod,
            kategoriId: data.kategoriId,
            gorsel: data.gorselUrl,
          );
          await _urunService.addUrun(yeniUrun);
          
          // Kategori adetini güncelle (Basit bir çözüm)
          final kat = _kategoriler.firstWhere((k) => k.id == data.kategoriId);
          await _kategoriService.updateKategori(Kategori(
            id: kat.id,
            kategoriId: kat.kategoriId,
            isim: kat.isim,
            cesit: kat.cesit + 1,
            adet: kat.adet + data.stok,
          ));
        },
      ),
    );
  }

  Future<void> _urunDuzenleDialog(Urun u) async {
    await showDialog(
      context: context,
      builder: (context) => UrunDialog(
        existingUrun: u,
        kategoriler: _kategoriler,
        onSubmit: (data) async {
          final guncelUrun = Urun(
            id: u.id,
            urunId: u.urunId,
            isim: data.isim,
            alisFiyat: data.alisFiyat,
            satisFiyat: data.satisFiyat,
            stok: data.stok,
            barkod: data.barkod,
            kategoriId: data.kategoriId,
            gorsel: data.gorselUrl,
          );
          await _urunService.updateUrun(guncelUrun);
          
          if (u.kategoriId != data.kategoriId) {
             try {
               final eskiKat = _kategoriler.firstWhere((k) => k.id == u.kategoriId);
               if (eskiKat.cesit > 0) {
                 await _kategoriService.updateKategori(Kategori(id: eskiKat.id, kategoriId: eskiKat.kategoriId, isim: eskiKat.isim, cesit: eskiKat.cesit - 1, adet: eskiKat.adet - u.stok));
               }
               final yeniKat = _kategoriler.firstWhere((k) => k.id == data.kategoriId);
               await _kategoriService.updateKategori(Kategori(id: yeniKat.id, kategoriId: yeniKat.kategoriId, isim: yeniKat.isim, cesit: yeniKat.cesit + 1, adet: yeniKat.adet + data.stok));
             } catch(e) {}
          } else {
             if (u.stok != data.stok) {
               try {
                 final kat = _kategoriler.firstWhere((k) => k.id == data.kategoriId);
                 await _kategoriService.updateKategori(Kategori(id: kat.id, kategoriId: kat.kategoriId, isim: kat.isim, cesit: kat.cesit, adet: kat.adet + (data.stok - u.stok)));
               } catch(e) {}
             }
          }
        },
      ),
    );
  }

  Future<void> _kategoriSilDialog(Kategori k) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori Silinecek'),
        content: Text('${k.isim} kategorisini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Sil', style: TextStyle(color: HesapixColors.danger))
          ),
        ],
      ),
    );
    if (confirm == true && k.id != null) {
      await _kategoriService.deleteKategori(k.id!);
      _snack('Kategori silindi.');
    }
  }

  Future<void> _urunSilDialog(Urun u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürün Silinecek'),
        content: Text('${u.isim} ürününü silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Sil', style: TextStyle(color: HesapixColors.danger))
          ),
        ],
      ),
    );
    if (confirm == true && u.id != null) {
      await _urunService.deleteUrun(u.id!);
      
      try {
         final kat = _kategoriler.firstWhere((k) => k.id == u.kategoriId);
         if (kat.cesit > 0) {
           await _kategoriService.updateKategori(Kategori(id: kat.id, kategoriId: kat.kategoriId, isim: kat.isim, cesit: kat.cesit - 1, adet: kat.adet - u.stok));
         }
      } catch(e) {}
      
      _snack('Ürün silindi.');
    }
  }

  void _showUrunDetayDialog(Urun u, String? kategoriIsim) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(u.isim, style: const TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (u.gorsel.isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        u.gorsel,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150, width: 150,
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _detailRow('Kategori:', kategoriIsim ?? '-'),
                _detailRow('Stok Adedi:', '${u.stok}'),
                _detailRow('Alış Fiyatı:', '₺${u.alisFiyat}'),
                _detailRow('Satış Fiyatı:', '₺${u.satisFiyat}'),
                _detailRow('Barkod:', u.barkod),
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
        title: const Text('Stok Yönetimi', style: TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: HesapixColors.primary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: HesapixColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: HesapixColors.primary,
          tabs: const [
            Tab(text: 'Ürünler'),
            Tab(text: 'Kategoriler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUrunlerTab(),
          _buildKategorilerTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _urunEkleDialog();
          } else {
            _kategoriEkleDialog();
          }
        },
        backgroundColor: HesapixColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildKategorilerTab() {
    if (_kategoriler.isEmpty) {
      return const Center(child: Text("Henüz kategori yok."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _kategoriler.length,
      itemBuilder: (context, index) {
        final k = _kategoriler[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: HesapixColors.primary.withOpacity(0.1),
              child: Text(k.kategoriId.toString(), style: const TextStyle(color: HesapixColors.primary)),
            ),
            title: Text(k.isim, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Çeşit: ${k.cesit} | Toplam Adet: ${k.adet}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _kategoriDuzenleDialog(k),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: HesapixColors.danger),
                  onPressed: () => _kategoriSilDialog(k),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUrunlerTab() {
    return StreamBuilder<List<Urun>>(
      stream: _urunService.getUrunler(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final urunler = snapshot.data ?? [];
        if (urunler.isEmpty) {
          return const Center(child: Text("Henüz ürün yok."));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: urunler.length,
          itemBuilder: (context, index) {
            final u = urunler[index];
            final kat = _kategoriler.where((k) => k.id == u.kategoriId).firstOrNull;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                onTap: () => _showUrunDetayDialog(u, kat?.isim),
                leading: u.gorsel.isNotEmpty 
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        u.gorsel, 
                        width: 50, height: 50, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 50, height: 50, 
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    )
                  : Container(
                      width: 50, height: 50, 
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.inventory, color: Colors.grey),
                    ),
                title: Text(u.isim, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () => _urunDuzenleDialog(u),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: HesapixColors.danger),
                      onPressed: () => _urunSilDialog(u),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
