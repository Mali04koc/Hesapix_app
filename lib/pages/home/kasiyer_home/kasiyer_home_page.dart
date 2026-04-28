import 'package:flutter/material.dart';
import 'package:hesapix_app/app_routes.dart';
import 'package:hesapix_app/services/session_service.dart';

class KasiyerHomePage extends StatelessWidget {
  const KasiyerHomePage({super.key});

  static const List<_MenuItem> _kasiyerMenuItems = [
    _MenuItem(title: 'Fiyat Gör', route: AppRoutes.fiyatGor),
    _MenuItem(title: 'Satış Faturası', route: AppRoutes.satisFaturasi),
    _MenuItem(
      title: 'Cari Hesap Yönetimi',
      route: AppRoutes.cariHesapYonetimi,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasiyer Panel'),
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
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _kasiyerMenuItems.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _kasiyerMenuItems[index];
          return SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed(item.route),
              child: Text(item.title),
            ),
          );
        },
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

