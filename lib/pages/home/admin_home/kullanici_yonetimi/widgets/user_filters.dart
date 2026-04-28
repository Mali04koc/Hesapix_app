import 'package:flutter/material.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

class UserFilters extends StatelessWidget {
  const UserFilters({
    super.key,
    required this.searchController,
    required this.rolFilter,
    required this.aktifFilter,
    required this.onRolChanged,
    required this.onAktifChanged,
  });

  final TextEditingController searchController;
  final String? rolFilter;
  final bool? aktifFilter;
  final ValueChanged<String?> onRolChanged;
  final ValueChanged<bool?> onAktifChanged;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HesapixColors.border),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchField(controller: searchController),
                const SizedBox(height: 12),
                _RolDropdown(
                  value: rolFilter,
                  onChanged: onRolChanged,
                ),
                const SizedBox(height: 12),
                _DurumDropdown(
                  value: aktifFilter,
                  onChanged: onAktifChanged,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: _SearchField(controller: searchController)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: _RolDropdown(
                    value: rolFilter,
                    onChanged: onRolChanged,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: _DurumDropdown(
                    value: aktifFilter,
                    onChanged: onAktifChanged,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'İsim veya e-posta ara…',
        hintStyle: const TextStyle(color: HesapixColors.textMuted, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: HesapixColors.primary),
        filled: true,
        fillColor: HesapixColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HesapixColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HesapixColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HesapixColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }
}

class _RolDropdown extends StatelessWidget {
  const _RolDropdown({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      key: ValueKey('rol_$value'),
      initialValue: value,
      decoration: _dropdownDeco('Rol'),
      items: const [
        DropdownMenuItem(value: null, child: Text('Tümü')),
        DropdownMenuItem(value: 'Admin', child: Text('Admin')),
        DropdownMenuItem(value: 'Kasiyer', child: Text('Kasiyer')),
      ],
      onChanged: onChanged,
    );
  }
}

class _DurumDropdown extends StatelessWidget {
  const _DurumDropdown({
    required this.value,
    required this.onChanged,
  });

  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<bool?>(
      key: ValueKey('durum_$value'),
      initialValue: value,
      decoration: _dropdownDeco('Durum'),
      items: const [
        DropdownMenuItem(value: null, child: Text('Tümü')),
        DropdownMenuItem(value: true, child: Text('Aktif')),
        DropdownMenuItem(value: false, child: Text('Pasif')),
      ],
      onChanged: onChanged,
    );
  }
}

InputDecoration _dropdownDeco(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: HesapixColors.textMuted, fontSize: 13),
    filled: true,
    fillColor: HesapixColors.bg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
}
