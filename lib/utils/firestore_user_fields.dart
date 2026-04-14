/// Firestore'da [rol] alanı bazen farklı yazılabildiği için okuma yardımcıları.
String readRoleFromData(Map<String, dynamic> data) {
  for (final entry in data.entries) {
    final key = entry.key
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll(' ', '');
    if (key == 'rol') {
      return (entry.value ?? '').toString().trim();
    }
  }
  return 'Kasiyer';
}

bool isAdminRoleValue(String rol) {
  final r = rol
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll(' ', '');
  return r == 'admin';
}
