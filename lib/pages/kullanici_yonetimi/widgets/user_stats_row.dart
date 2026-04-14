import 'package:flutter/material.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

/// Üç metrik: Toplam, Aktif, Admin (Kasiyer = toplam − admin).
class UserStatsRow extends StatelessWidget {
  const UserStatsRow({
    super.key,
    required this.total,
    required this.active,
    required this.adminCount,
  });

  final int total;
  final int active;
  final int adminCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 520;
        if (narrow) {
          return Column(
            children: [
              _StatTile(
                icon: Icons.groups_outlined,
                label: 'Toplam Kullanıcı',
                value: '$total',
                accent: HesapixColors.primary,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.verified_outlined,
                      label: 'Aktif',
                      value: '$active',
                      accent: HesapixColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.shield_outlined,
                      label: 'Admin',
                      value: '$adminCount',
                      accent: HesapixColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.groups_outlined,
                label: 'Toplam Kullanıcı',
                value: '$total',
                accent: HesapixColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.verified_outlined,
                label: 'Aktif Kullanıcı',
                value: '$active',
                accent: HesapixColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.shield_outlined,
                label: 'Admin Sayısı',
                value: '$adminCount',
                accent: HesapixColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HesapixColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: HesapixColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: HesapixColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
