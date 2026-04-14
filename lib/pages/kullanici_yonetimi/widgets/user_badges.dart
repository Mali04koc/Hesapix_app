import 'package:flutter/material.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/utils/firestore_user_fields.dart';

class UserRoleBadge extends StatelessWidget {
  const UserRoleBadge({super.key, required this.rol});

  final String rol;

  @override
  Widget build(BuildContext context) {
    final admin = isAdminRoleValue(rol);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: admin ? HesapixColors.primaryContainer : HesapixColors.accentContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: admin
              ? HesapixColors.primary.withValues(alpha: 0.25)
              : HesapixColors.accent.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            admin ? Icons.shield_outlined : Icons.badge_outlined,
            size: 13,
            color: admin ? HesapixColors.primary : HesapixColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            admin ? 'Admin' : 'Kasiyer',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: admin ? HesapixColors.primary : HesapixColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class UserStatusBadge extends StatelessWidget {
  const UserStatusBadge({super.key, required this.aktif});

  final bool aktif;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: aktif
            ? HesapixColors.success.withValues(alpha: 0.12)
            : HesapixColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            aktif ? Icons.circle : Icons.circle_outlined,
            size: 9,
            color: aktif ? HesapixColors.success : HesapixColors.danger,
          ),
          const SizedBox(width: 5),
          Text(
            aktif ? 'Aktif' : 'Pasif',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: aktif ? HesapixColors.success : HesapixColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
