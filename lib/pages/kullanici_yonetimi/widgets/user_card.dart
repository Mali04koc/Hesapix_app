import 'package:flutter/material.dart';
import 'package:hesapix_app/models/app_user_model.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/pages/kullanici_yonetimi/widgets/user_badges.dart';

class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.user,
    required this.isSelf,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final AppUserModel user;
  final bool isSelf;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HesapixColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    user.adSoyad,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: HesapixColors.textPrimary,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: HesapixColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (v) {
                    switch (v) {
                      case 'edit':
                        onEdit();
                      case 'toggle':
                        if (!isSelf) onToggle();
                      case 'delete':
                        if (!isSelf) onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      enabled: !isSelf,
                      child: Row(
                        children: [
                          Icon(
                            user.aktif
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(user.aktif ? 'Pasif yap' : 'Aktif yap'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      enabled: !isSelf,
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: HesapixColors.danger),
                          SizedBox(width: 10),
                          Text('Sil', style: TextStyle(color: HesapixColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                UserRoleBadge(rol: user.rol),
                UserStatusBadge(aktif: user.aktif),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              user.email,
              style: const TextStyle(
                fontSize: 13,
                color: HesapixColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
