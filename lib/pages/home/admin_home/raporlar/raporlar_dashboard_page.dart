import 'package:flutter/material.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'satis_raporlari_page.dart';
import 'alis_raporlari_page.dart';
import 'cari_raporlari_page.dart';
import 'stok_raporlari_page.dart';
import 'karlilik_raporlari_page.dart';
import 'kullanici_raporlari_page.dart';
import 'tahsilat_raporlari_page.dart';
import 'trend_raporlari_page.dart';

class RaporlarDashboardPage extends StatelessWidget {
  const RaporlarDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Kârlılık Raporları',
        'icon': Icons.monetization_on,
        'color': Colors.amber,
        'page': const KarlilikRaporlariPage(),
      },
      {
        'title': 'Trend Raporları (Grafik)',
        'icon': Icons.show_chart,
        'color': Colors.teal,
        'page': const TrendRaporlariPage(),
      },
      {
        'title': 'Satış Raporları',
        'icon': Icons.trending_up,
        'color': Colors.blue,
        'page': const SatisRaporlariPage(),
      },
      {
        'title': 'Alış Raporları',
        'icon': Icons.shopping_cart,
        'color': Colors.orange,
        'page': const AlisRaporlariPage(),
      },
      {
        'title': 'Cari Hesap Raporları',
        'icon': Icons.account_balance_wallet,
        'color': Colors.purple,
        'page': const CariRaporlariPage(),
      },
      {
        'title': 'Stok Raporları',
        'icon': Icons.inventory,
        'color': Colors.green,
        'page': const StokRaporlariPage(),
      },
      {
        'title': 'Tahsilat Raporları',
        'icon': Icons.receipt_long,
        'color': Colors.indigo,
        'page': const TahsilatRaporlariPage(),
      },
      {
        'title': 'Personel Raporları',
        'icon': Icons.people,
        'color': Colors.brown,
        'page': const KullaniciRaporlariPage(),
      },
    ];

    return Scaffold(
      backgroundColor: HesapixColors.bg,
      appBar: AppBar(
        title: const Text('Raporlar', style: TextStyle(fontWeight: FontWeight.bold, color: HesapixColors.primary)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: HesapixColors.primary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0, // Daha kare yaparak dikey alan kazandık
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => item['page']),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: item['color'].withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'],
                          size: 40, // Boyutu biraz küçülttük
                          color: item['color'],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: Text(
                          item['title'],
                          style: const TextStyle(
                            fontSize: 14, // Yazı boyutunu biraz küçülttük
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
