import 'package:flutter/material.dart';
import 'package:hesapix_app/models/app_user_model.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/pages/kullanici_yonetimi/widgets/user_badges.dart';

class UserTable extends StatelessWidget {
  const UserTable({
    super.key,
    required this.users,
    required this.currentUserId,
    required this.formatDate,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final List<AppUserModel> users;
  final String currentUserId;
  final String Function(DateTime?) formatDate;
  final void Function(AppUserModel user) onEdit;
  final void Function(AppUserModel user) onToggleActive;
  final void Function(AppUserModel user) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HesapixColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 52,
              horizontalMargin: 20,
              columnSpacing: 24,
              headingRowColor: WidgetStateProperty.all(
                HesapixColors.primary.withValues(alpha: 0.06),
              ),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                color: HesapixColors.primary,
                fontSize: 13,
              ),
              dataTextStyle: const TextStyle(
                fontSize: 13,
                color: HesapixColors.textPrimary,
              ),
              columns: const [
                DataColumn(label: Text('Ad Soyad')),
                DataColumn(label: Text('E-posta')),
                DataColumn(label: Text('Rol')),
                DataColumn(label: Text('Durum')),
                DataColumn(label: Text('Son Giriş')),
                DataColumn(label: Text('Oluşturulma')),
                DataColumn(label: Text('İşlemler')),
              ],
              rows: users.map((u) {
                final isSelf = u.id == currentUserId;
                return DataRow(
                  color: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return HesapixColors.primary.withValues(alpha: 0.04);
                    }
                    return null;
                  }),
                  cells: [
                    DataCell(
                      Text(
                        u.adSoyad,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(Text(u.email)),
                    DataCell(UserRoleBadge(rol: u.rol)),
                    DataCell(UserStatusBadge(aktif: u.aktif)),
                    DataCell(Text(formatDate(u.sonGirisTarihi))),
                    DataCell(Text(formatDate(u.olusturulmaTarihi))),
                    DataCell(
                      _RowMenu(
                        user: u,
                        isSelf: isSelf,
                        onEdit: () => onEdit(u),
                        onToggle: () => onToggleActive(u),
                        onDelete: () => onDelete(u),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({
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
    return PopupMenuButton<String>(
      tooltip: 'İşlemler',
      icon: const Icon(Icons.more_vert, color: HesapixColors.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                user.aktif ? Icons.pause_circle_outline : Icons.play_circle_outline,
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
    );
  }
}
