import 'package:flutter/material.dart';
import 'package:hesapix_app/models/tedarikci_model.dart';
import 'package:hesapix_app/services/tedarikci_service.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/pages/home/admin_home/tedarikci_yonetimi/dialogs/tedarikci_dialog.dart';

class TedarikciYonetimiPage extends StatefulWidget {
  const TedarikciYonetimiPage({super.key});

  @override
  State<TedarikciYonetimiPage> createState() => _TedarikciYonetimiPageState();
}

class _TedarikciYonetimiPageState extends State<TedarikciYonetimiPage> {
  final TedarikciService _tedarikciService = TedarikciService();
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  late Stream<List<Tedarikci>> _tedarikcilerStream;

  @override
  void initState() {
    super.initState();
    _tedarikcilerStream = _tedarikciService.getTedarikciler();
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

  Future<void> _tedarikciEkleDialog() async {
    await showDialog(
      context: context,
      builder: (context) => TedarikciDialog(
        onSubmit: (data) async {
          // Calculate the next ID
          int nextId = 1;
          try {
            final tList = await _tedarikciService.getTedarikciler().first;
            if (tList.isNotEmpty) {
              final maxId = tList.map((e) => e.tedarikciId).reduce((a, b) => a > b ? a : b);
              nextId = maxId + 1;
            }
          } catch(e) {}

          final yeniTedarikci = Tedarikci(
            tedarikciId: nextId,
            isim: data.isim,
            telefon: data.telefon,
            adres: data.adres,
            borc: data.borc,
            tedarikciKodu: data.tedarikciKodu,
            taksit: data.taksit,
            aylikOdeme: data.aylikOdeme,
          );
          await _tedarikciService.addTedarikci(yeniTedarikci);
          _snack('Tedarikçi eklendi.');
        },
      ),
    );
  }

  Future<void> _tedarikciDuzenleDialog(Tedarikci t) async {
    await showDialog(
      context: context,
      builder: (context) => TedarikciDialog(
        existingTedarikci: t,
        onSubmit: (data) async {
          final guncelTedarikci = Tedarikci(
            id: t.id,
            tedarikciId: t.tedarikciId,
            isim: data.isim,
            telefon: data.telefon,
            adres: data.adres,
            borc: data.borc,
            tedarikciKodu: data.tedarikciKodu,
            taksit: data.taksit,
            aylikOdeme: data.aylikOdeme,
          );
          await _tedarikciService.updateTedarikci(guncelTedarikci);
          _snack('Tedarikçi güncellendi.');
        },
      ),
    );
  }

  Future<void> _tedarikciSilDialog(Tedarikci t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tedarikçi Silinecek'),
        content: Text('${t.isim} isimli tedarikçiyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Sil', style: TextStyle(color: HesapixColors.danger))
          ),
        ],
      ),
    );
    if (confirm == true && t.id != null) {
      await _tedarikciService.deleteTedarikci(t.id!);
      _snack('Tedarikçi silindi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Tedarikçi Yönetimi', style: TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
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
                hintText: 'İsim veya Tedarikçi Kodu ile Ara',
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
            child: StreamBuilder<List<Tedarikci>>(
              stream: _tedarikcilerStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                
                final filteredList = list.where((t) {
                  final query = _searchQuery.toLowerCase();
                  return t.isim.toLowerCase().contains(query) ||
                         t.tedarikciKodu.toLowerCase().contains(query);
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(child: Text("Sonuç bulunamadı."));
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final t = filteredList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: HesapixColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.business, color: HesapixColors.primary),
                          ),
                          title: Text(t.isim, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.grey),
                                onPressed: () => _tedarikciDuzenleDialog(t),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: HesapixColors.danger),
                                onPressed: () => _tedarikciSilDialog(t),
                              ),
                              const Icon(Icons.expand_more, color: Colors.grey),
                            ],
                          ),
                          childrenPadding: const EdgeInsets.only(left: 72, right: 16, bottom: 16),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailText('İsim:', t.isim),
                            _buildDetailText('Telefon:', '+90 ${t.telefon}'),
                            _buildDetailText('Adres:', t.adres),
                            _buildDetailText('Borç:', '₺${t.borc.toStringAsFixed(2)}'),
                            _buildDetailText('Taksit:', '${t.taksit}'),
                            _buildDetailText('Aylık Ödeme:', '₺${t.aylikOdeme.toStringAsFixed(2)}', isHighlight: true),
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
        onPressed: _tedarikciEkleDialog,
        backgroundColor: HesapixColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDetailText(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? HesapixColors.primary : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
