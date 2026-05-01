import 'package:flutter/material.dart';
import 'package:hesapix_app/app_routes.dart';
import 'package:hesapix_app/services/session_service.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  static const List<_MenuItem> _adminMenuItems = [
    _MenuItem(title: 'Fiyat Gör', route: AppRoutes.fiyatGor, icon: Icons.search),
    _MenuItem(title: 'Stok Yönetimi', route: AppRoutes.stokYonetimi, icon: Icons.inventory_2),
    _MenuItem(title: 'Satış Faturası', route: AppRoutes.satisFaturasi, icon: Icons.receipt_long),
    _MenuItem(title: 'Alış Faturası', route: AppRoutes.alisFaturasi, icon: Icons.shopping_cart),
    _MenuItem(title: 'Cari Hesap', route: AppRoutes.cariHesapYonetimi, icon: Icons.people),
    _MenuItem(title: 'Ödeme İşlemleri', route: AppRoutes.odemeIslemleri, icon: Icons.payment),
    _MenuItem(title: 'Raporlar', route: AppRoutes.raporlar, icon: Icons.bar_chart),
    _MenuItem(title: 'Kullanıcılar', route: AppRoutes.kullaniciYonetimi, icon: Icons.manage_accounts),
    _MenuItem(title: 'Stok Geçmişi', route: AppRoutes.stokHareketGecmisi, icon: Icons.history),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hesapix Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              await SessionService().clear();
              if (!context.mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
            },
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1.1,
        ),
        itemCount: _adminMenuItems.length,
        itemBuilder: (context, index) {
          final item = _adminMenuItems[index];
          return _MenuCard(item: item);
        },
      ),
    );
  }
}

class _MenuCard extends StatefulWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.white : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isHovered 
                ? Colors.black.withOpacity(0.1) 
                : Colors.black.withOpacity(0.05),
              blurRadius: _isHovered ? 15 : 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: _isHovered ? const Color(0xFF4F46E5) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).pushNamed(widget.item.route),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.item.icon,
                  size: 40,
                  color: _isHovered ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _isHovered ? const Color(0xFF4F46E5) : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.title,
    required this.route,
    required this.icon,
  });

  final String title;
  final String route;
  final IconData icon;
}

