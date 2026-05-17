import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/app_routes.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

void main() {
  group('AppRoutes', () {
    test('tüm rota sabitleri tanımlı ve benzersiz', () {
      const routes = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.adminHome,
        AppRoutes.kasiyerHome,
        AppRoutes.forgotPassword,
        AppRoutes.fiyatGor,
        AppRoutes.stokYonetimi,
        AppRoutes.satisFaturasi,
        AppRoutes.alisFaturasi,
        AppRoutes.cariHesapYonetimi,
        AppRoutes.raporlar,
        AppRoutes.kullaniciYonetimi,
        AppRoutes.finansYonetimi,
        AppRoutes.odemeIslemleri,
      ];

      expect(routes.every((r) => r.startsWith('/')), isTrue);
      expect(routes.toSet().length, routes.length);
    });
  });

  group('HesapixColors', () {
    test('kurumsal renkler doğru hex değerlerine sahip', () {
      expect(HesapixColors.primary, const Color(0xFF004080));
      expect(HesapixColors.accent, const Color(0xFFFF8C00));
      expect(HesapixColors.danger, const Color(0xFFDC2626));
      expect(HesapixColors.success, const Color(0xFF16A34A));
    });
  });
}
