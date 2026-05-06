import 'package:flutter/material.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/services/cari_service.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/pages/home/admin_home/cari_yonetimi/dialogs/cari_dialog.dart';
import 'package:hesapix_app/pages/home/admin_home/satıs_arayuz/satis_faturasi_detay_page.dart';

class SatisFaturasiCariSecimPage extends StatefulWidget {
  const SatisFaturasiCariSecimPage({super.key});

  @override
  State<SatisFaturasiCariSecimPage> createState() => _SatisFaturasiCariSecimPageState();
}

class _SatisFaturasiCariSecimPageState extends State<SatisFaturasiCariSecimPage> {
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

  void _cariSec(Cari cari) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SatisFaturasiDetayPage(cari: cari),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Satış Faturası - Cari Seçin', style: TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
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
                  return const Center(child: Text("Cari bulunamadı. Lütfen yeni bir cari ekleyin."));
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredCariler.length,
                  itemBuilder: (context, index) {
                    final c = filteredCariler[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () => _cariSec(c),
                        leading: CircleAvatar(
                          backgroundColor: HesapixColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.business, color: HesapixColors.primary),
                        ),
                        title: Text('${c.cariKodu} - ${c.firmaAdi}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('Vergi No: ${c.vergiNo.isNotEmpty ? c.vergiNo : '-'}'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cariEkleDialog,
        backgroundColor: HesapixColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Yeni Cari Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
