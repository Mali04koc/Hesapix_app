import 'package:flutter/material.dart';
import 'package:hesapix_app/app_routes.dart';
import 'package:hesapix_app/services/session_service.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  static const List<_MenuItem> _adminMenuItems = [
    _MenuItem(title: 'Fiyat Gör', route: AppRoutes.fiyatGor),
    _MenuItem(title: 'Stok Yönetimi', route: AppRoutes.stokYonetimi),
    _MenuItem(title: 'Satış Faturası', route: AppRoutes.satisFaturasi),
    _MenuItem(title: 'Alış Faturası', route: AppRoutes.alisFaturasi),
    _MenuItem(
      title: 'Cari Hesap Yönetimi',
      route: AppRoutes.cariHesapYonetimi,
    ),
    _MenuItem(title: 'Raporlar', route: AppRoutes.raporlar),
    _MenuItem(
      title: 'Kullanıcı Yönetimi',
      route: AppRoutes.kullaniciYonetimi,
    ),
    _MenuItem(title: 'Finans Yönetimi', route: AppRoutes.finansYonetimi),
    _MenuItem(
      title: 'Stok Hareket Geçmişi',
      route: AppRoutes.stokHareketGecmisi,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              await SessionService().clear();
              if (!context.mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _DashboardCard(title: 'Günlük Satış', value: '-'),
              _DashboardCard(title: 'Aylık Ciro', value: '-'),
              _DashboardCard(title: 'En Çok Satan Ürün', value: '-'),
              _DashboardCard(title: 'Toplam Borç / Alacak', value: '-'),
            ],
          ),
          const SizedBox(height: 20),
          ..._adminMenuItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed(item.route),
                  child: Text(item.title),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
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
  });

  final String title;
  final String route;
}

