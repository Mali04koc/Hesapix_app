import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/services/rapor_service.dart';
import 'package:hesapix_app/models/satis_model.dart';
import 'package:intl/intl.dart';

class TrendRaporlariPage extends StatefulWidget {
  const TrendRaporlariPage({super.key});

  @override
  State<TrendRaporlariPage> createState() => _TrendRaporlariPageState();
}

class _TrendRaporlariPageState extends State<TrendRaporlariPage> {
  final RaporService _raporService = RaporService();
  
  // Varsayılan olarak son 30 gün
  DateTime _baslangic = DateTime.now().subtract(const Duration(days: 29));
  DateTime _bitis = DateTime.now();
  
  List<Satis> _satislar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verileriGetir();
  }

  Future<void> _verileriGetir() async {
    setState(() => _isLoading = true);
    try {
      _satislar = await _raporService.getSatislar(_baslangic, _bitis);
    } catch (e) {
      debugPrint('Trend Rapor Hatasi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verileri günlere göre grupla
    Map<String, double> gunlukSatis = {};
    
    // Son 30 günü 0 ile doldur
    for(int i = 0; i <= _bitis.difference(_baslangic).inDays; i++) {
      final tarih = _baslangic.add(Duration(days: i));
      final gunKey = DateFormat('dd.MM').format(tarih);
      gunlukSatis[gunKey] = 0.0;
    }

    // Gerçek verileri üstüne yaz
    for (var s in _satislar) {
      final gunKey = DateFormat('dd.MM').format(s.tarih);
      if (gunlukSatis.containsKey(gunKey)) {
        gunlukSatis[gunKey] = gunlukSatis[gunKey]! + s.genelToplam;
      }
    }

    final veriler = gunlukSatis.entries.toList();
    
    List<FlSpot> satisNoktalari = [];
    double maxDeger = 0;
    
    for (int i = 0; i < veriler.length; i++) {
      final deger = veriler[i].value;
      if (deger > maxDeger) maxDeger = deger;
      satisNoktalari.add(FlSpot(i.toDouble(), deger));
    }

    // Y ekseni max değerini biraz yuvarla (Grafik tepesi sıkışmasın)
    final maxY = maxDeger == 0 ? 1000.0 : maxDeger * 1.2;

    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Trend Analizi (Son 30 Gün)', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Günlük Ciro Trendi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.only(right: 16, left: 0, top: 24, bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 5)
                      ]
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index < 0 || index >= veriler.length) return const Text('');
                                // Çok fazla gün varsa sadece belirli aralıklarla göster (Örn. 5 günde 1)
                                if (veriler.length > 10 && index % 5 != 0 && index != veriler.length - 1) return const Text('');
                                
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(veriler[index].key, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value == maxY) return const Text('');
                                return Text(
                                  value >= 1000 ? '${(value/1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0), 
                                  style: const TextStyle(color: Colors.grey, fontSize: 10)
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (veriler.length - 1).toDouble(),
                        minY: 0,
                        maxY: maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: satisNoktalari,
                            isCurved: true,
                            color: HesapixColors.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: HesapixColors.primary.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Trend Analiz Notu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Yukarıdaki grafik, son 30 güne ait günlük ciro hareketlerini göstermektedir. '
                    'İşletmenin haftasonu/haftaiçi veya ayın belirli günlerinde yaşadığı dalgalanmaları buradan takip edebilirsiniz.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}
