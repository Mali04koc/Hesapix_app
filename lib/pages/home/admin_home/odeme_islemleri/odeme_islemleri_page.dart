import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';
import 'package:hesapix_app/services/cari_service.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

class OdemeIslemleriPage extends StatefulWidget {
  const OdemeIslemleriPage({super.key});

  @override
  State<OdemeIslemleriPage> createState() => _OdemeIslemleriPageState();
}

class _OdemeIslemleriPageState extends State<OdemeIslemleriPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CariService _cariService = CariService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Ödeme İşlemleri', style: TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: HesapixColors.primary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: HesapixColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: HesapixColors.primary,
          tabs: const [
            Tab(text: 'Son İşlemler'),
            Tab(text: 'Ödeme Al'),
            Tab(text: 'Ödeme Yap'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IslemGecmisi(cariService: _cariService),
          _OdemeForm(islemTipi: 'ODEME_AL', cariService: _cariService),
          _OdemeForm(islemTipi: 'ODEME_YAP', cariService: _cariService),
        ],
      ),
    );
  }
}

class _OdemeForm extends StatefulWidget {
  final String islemTipi;
  final CariService cariService;

  const _OdemeForm({required this.islemTipi, required this.cariService});

  @override
  State<_OdemeForm> createState() => _OdemeFormState();
}

class _OdemeFormState extends State<_OdemeForm> {
  final _formKey = GlobalKey<FormState>();
  Cari? _secilenCari;
  final TextEditingController _aramaCtrl = TextEditingController();
  final TextEditingController _tutarCtrl = TextEditingController();
  final TextEditingController _aciklamaCtrl = TextEditingController();
  List<Cari> _aramaSonuclari = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _aramaCtrl.dispose();
    _tutarCtrl.dispose();
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cariAra(String arama) async {
    if (arama.isEmpty) {
      setState(() {
        _aramaSonuclari = [];
      });
      return;
    }

    setState(() => _isLoading = true);
    final sonuclar = await widget.cariService.cariAra(arama);
    setState(() {
      _aramaSonuclari = sonuclar;
      _isLoading = false;
    });
  }

  void _kaydet() async {
    if (_secilenCari == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir cari seçin.')));
      return;
    }

    if (_formKey.currentState!.validate()) {
      final tutar = double.tryParse(_tutarCtrl.text.trim()) ?? 0.0;
      final aciklama = _aciklamaCtrl.text.trim();

      final hareket = CariHareket(
        cariId: _secilenCari!.id!,
        islemTipi: widget.islemTipi,
        tarih: DateTime.now(),
        tutar: tutar,
        aciklama: aciklama,
      );

      await widget.cariService.addHareket(hareket);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.islemTipi == 'ODEME_AL' ? 'Ödeme Alındı' : 'Ödeme Yapıldı'}!'),
          backgroundColor: HesapixColors.success,
        )
      );

      _formKey.currentState!.reset();
      setState(() {
        _secilenCari = null;
        _aramaCtrl.clear();
        _tutarCtrl.clear();
        _aciklamaCtrl.clear();
        _aramaSonuclari = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_secilenCari == null) ...[
              TextField(
                controller: _aramaCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari Ara (Kodu veya Firma Adı)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: _cariAra,
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_aramaSonuclari.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _aramaSonuclari.length,
                    itemBuilder: (context, index) {
                      final cari = _aramaSonuclari[index];
                      return ListTile(
                        title: Text(cari.firmaAdi),
                        subtitle: Text(cari.cariKodu),
                        trailing: const Icon(Icons.check_circle_outline),
                        onTap: () {
                          setState(() {
                            _secilenCari = cari;
                            _aramaCtrl.text = cari.firmaAdi;
                            _aramaSonuclari = [];
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
            ] else ...[
              Card(
                color: HesapixColors.primary.withOpacity(0.05),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: HesapixColors.primary)),
                child: ListTile(
                  leading: const Icon(Icons.business, color: HesapixColors.primary),
                  title: Text(_secilenCari!.firmaAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Cari Kodu: ${_secilenCari!.cariKodu}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _secilenCari = null;
                        _aramaCtrl.clear();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            TextFormField(
              controller: _tutarCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Tutar (₺)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Tutar zorunludur';
                if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Geçerli bir tutar girin';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aciklamaCtrl,
              decoration: InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _kaydet,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.islemTipi == 'ODEME_AL' ? HesapixColors.success : HesapixColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                widget.islemTipi == 'ODEME_AL' ? 'Ödemeyi Al ve Kaydet' : 'Ödeme Yap ve Kaydet',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IslemGecmisi extends StatelessWidget {
  final CariService cariService;
  const _IslemGecmisi({required this.cariService});

  String _islemAdi(String tip) {
    switch (tip) {
      case 'SATIS': return 'Satış Faturası';
      case 'ALIS': return 'Alış Faturası';
      case 'ODEME_AL': return 'Ödeme Alındı';
      case 'ODEME_YAP': return 'Ödeme Yapıldı';
      default: return tip;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CariHareket>>(
      stream: cariService.getAllHareketler(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final hareketler = snapshot.data ?? [];
        if (hareketler.isEmpty) {
          return const Center(child: Text("Henüz işlem hareketi yok."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: hareketler.length,
          itemBuilder: (context, index) {
            final h = hareketler[index];
            final isPozitif = h.islemTipi == 'SATIS' || h.islemTipi == 'ODEME_YAP';
            
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('cariler').doc(h.cariId).get(),
              builder: (context, cSnap) {
                String cariAdi = 'Yükleniyor...';
                if (cSnap.hasData && cSnap.data!.exists) {
                  cariAdi = (cSnap.data!.data() as Map<String, dynamic>)['firma_adi'] ?? 'Bilinmeyen Cari';
                }
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPozitif ? HesapixColors.success.withOpacity(0.1) : HesapixColors.danger.withOpacity(0.1),
                      child: Icon(
                        isPozitif ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isPozitif ? HesapixColors.success : HesapixColors.danger,
                      ),
                    ),
                    title: Text(cariAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${_islemAdi(h.islemTipi)} • ${DateFormat('dd/MM/yyyy HH:mm').format(h.tarih)}\n${h.aciklama}'),
                    isThreeLine: true,
                    trailing: Text(
                      '${isPozitif ? '+' : '-'}₺${h.tutar.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isPozitif ? HesapixColors.success : HesapixColors.danger
                      ),
                    ),
                  ),
                );
              }
            );
          },
        );
      },
    );
  }
}

