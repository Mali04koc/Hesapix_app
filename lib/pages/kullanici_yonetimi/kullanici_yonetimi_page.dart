import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hesapix_app/app_routes.dart';
import 'package:hesapix_app/models/app_user_model.dart';
import 'package:hesapix_app/models/auth_user.dart';
import 'package:hesapix_app/pages/kullanici_yonetimi/dialogs/confirm_dialog.dart';
import 'package:hesapix_app/pages/kullanici_yonetimi/dialogs/user_dialog.dart';
import 'package:hesapix_app/pages/kullanici_yonetimi/widgets/user_card.dart';
import 'package:hesapix_app/pages/kullanici_yonetimi/widgets/user_filters.dart';
import 'package:hesapix_app/pages/kullanici_yonetimi/widgets/user_stats_row.dart';
import 'package:hesapix_app/pages/kullanici_yonetimi/widgets/user_table.dart';
import 'package:hesapix_app/pages/kullanici_yonetimi/widgets/user_table_skeleton.dart';
import 'package:hesapix_app/services/auth_service.dart';
import 'package:hesapix_app/services/session_service.dart';
import 'package:hesapix_app/services/user_service.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';
import 'package:hesapix_app/utils/firestore_user_fields.dart';

class KullaniciYonetimiPage extends StatefulWidget {
  const KullaniciYonetimiPage({super.key});

  @override
  State<KullaniciYonetimiPage> createState() => _KullaniciYonetimiPageState();
}

class _KullaniciYonetimiPageState extends State<KullaniciYonetimiPage> {
  final _userService = UserService();
  final _sessionService = SessionService();
  final _searchCtrl = TextEditingController();

  Future<AuthUser?>? _currentUserFuture;

  String _searchQuery = '';
  String? _rolFilter;
  bool? _aktifFilter;
  int _page = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _currentUserFuture = _sessionService.read();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim();
        _page = 0;
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _sessionIsAdmin(AuthUser? u) {
    if (u == null) return false;
    final r = u.role
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll(' ', '');
    return r == 'admin';
  }

  List<AppUserModel> _applyFilters(List<AppUserModel> all) {
    var list = List<AppUserModel>.from(all);
    final q = _searchQuery.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((u) {
        return u.adSoyad.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q);
      }).toList();
    }
    if (_rolFilter != null) {
      list = list.where((u) {
        if (_rolFilter == 'Admin') {
          return isAdminRoleValue(u.rol);
        }
        return !isAdminRoleValue(u.rol);
      }).toList();
    }
    if (_aktifFilter != null) {
      list = list.where((u) => u.aktif == _aktifFilter).toList();
    }
    return list;
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    final w = MediaQuery.sizeOf(context).width;
    final left = math.max(16.0, w - 400);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(left: left, right: 24, bottom: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: error ? HesapixColors.danger : HesapixColors.primary,
        content: Text(message),
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UserDialog(
        title: 'Yeni Kullanıcı',
        subtitle: 'Sisteme yeni hesap ekleyin',
        isEdit: false,
        onSubmit: (input) async {
          await _userService.createUser(
            adSoyad: input.adSoyad,
            email: input.email,
            password: input.password!,
            rol: input.rol,
            aktif: input.aktif,
          );
        },
      ),
    );
    if (saved == true && mounted) {
      await _sessionService.clear();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Kullanıcı oluşturuldu',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Güvenlik nedeniyle oturumunuz sonlandırıldı. '
            'Yönetici hesabınızla tekrar giriş yapın.\n\n'
            'İleride kullanıcı oluşturmayı oturumu değiştirmeden yapmak için '
            'Firebase Admin SDK veya Cloud Function kullanılmalıdır.',
            style: TextStyle(height: 1.45),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: HesapixColors.accent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (_) => false,
                  );
                }
              },
              child: const Text('Girişe git'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openEditDialog({
    required AppUserModel user,
    required String currentAdminId,
    required bool isSelf,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UserDialog(
        title: 'Kullanıcı Düzenle',
        subtitle: isSelf
            ? 'Kendi profiliniz — rol ve durum bu ekrandan değiştirilemez'
            : 'Bilgileri güncelleyin',
        isEdit: true,
        isEditingSelf: isSelf,
        existingUser: user,
        onSubmit: (input) async {
          await _userService.updateUser(
            userId: user.id,
            adSoyad: input.adSoyad,
            email: input.email,
            rol: input.rol,
            aktif: input.aktif,
            currentAdminId: currentAdminId,
          );
        },
      ),
    );
    if (saved == true && mounted) _snack('Kayıt güncellendi.');
  }

  Future<void> _deleteUser(AppUserModel user, String currentAdminId) async {
    final step1 = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Kullanıcı silinsin mi?',
        message: '${user.adSoyad} silinmek üzere. Bu adım geri alınamaz.',
        confirmLabel: 'Devam et',
        isDestructive: true,
      ),
    );
    if (step1 != true) return;
    if (!mounted) return;

    final step2 = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDialog(
        title: 'Son onay',
        message:
            'Firestore kaydı silinecek. Firebase Authentication hesabını da '
            'konsoldan kaldırmanız önerilir.',
        confirmLabel: 'Kalıcı olarak sil',
        isDestructive: true,
      ),
    );
    if (step2 != true) return;

    try {
      await _userService.deleteUser(
        userId: user.id,
        currentAdminId: currentAdminId,
      );
      if (mounted) {
        _snack('Kullanıcı silindi.');
      }
    } on AuthException catch (e) {
      _snack(e.message, error: true);
    }
  }

  Future<void> _toggleActive(
    AppUserModel user,
    String currentAdminId,
  ) async {
    final willBePassive = user.aktif;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: willBePassive ? 'Pasif yapılsın mı?' : 'Aktif yapılsın mı?',
        message: willBePassive
            ? '${user.adSoyad} giriş yapamayacak.'
            : '${user.adSoyad} tekrar giriş yapabilecek.',
        confirmLabel: willBePassive ? 'Pasif yap' : 'Aktif yap',
        isDestructive: willBePassive,
      ),
    );
    if (confirm != true) return;
    try {
      await _userService.setUserActive(
        userId: user.id,
        aktif: !user.aktif,
        currentAdminId: currentAdminId,
      );
      if (mounted) {
        _snack(
          !user.aktif
              ? 'Kullanıcı aktifleştirildi.'
              : 'Kullanıcı pasife alındı.',
        );
      }
    } on AuthException catch (e) {
      _snack(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 900;

    return FutureBuilder<AuthUser?>(
      future: _currentUserFuture,
      builder: (context, sessionSnap) {
        if (!sessionSnap.hasData) {
          return Scaffold(
            backgroundColor: HesapixColors.bg,
            body: const Center(
              child: CircularProgressIndicator(color: HesapixColors.primary),
            ),
          );
        }
        final current = sessionSnap.data;
        if (current == null || !_sessionIsAdmin(current)) {
          return Scaffold(
            backgroundColor: HesapixColors.bg,
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: HesapixColors.primary,
              title: const Text('Kullanıcı Yönetimi'),
            ),
            body: const Center(
              child: Text('Bu sayfaya erişim yetkiniz yok.'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: HesapixColors.bg,
          body: SafeArea(
            child: StreamBuilder<List<AppUserModel>>(
              stream: _userService.streamUsers(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _pageHeader(isNarrow: isNarrow),
                        const SizedBox(height: 24),
                        const UserTableSkeleton(),
                      ],
                    ),
                  );
                }

                final all = snap.data ?? [];
                final filtered = _applyFilters(all);
                final totalPages = filtered.isEmpty
                    ? 1
                    : ((filtered.length + _pageSize - 1) ~/ _pageSize);
                final maxPageIndex = totalPages - 1;
                final pageIndex = _page.clamp(0, maxPageIndex);
                final start = pageIndex * _pageSize;
                final pageItems = filtered.skip(start).take(_pageSize).toList();

                final adminCount =
                    all.where((u) => isAdminRoleValue(u.rol)).length;
                final activeCount = all.where((u) => u.aktif).length;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _pageHeader(isNarrow: isNarrow),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: UserStatsRow(
                        total: all.length,
                        active: activeCount,
                        adminCount: adminCount,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: UserFilters(
                        searchController: _searchCtrl,
                        rolFilter: _rolFilter,
                        aktifFilter: _aktifFilter,
                        onRolChanged: (v) => setState(() {
                          _rolFilter = v;
                          _page = 0;
                        }),
                        onAktifChanged: (v) => setState(() {
                          _aktifFilter = v;
                          _page = 0;
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: filtered.isEmpty
                          ? (all.isEmpty ? _emptyState() : _noResultsState())
                          : isNarrow
                              ? ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 24),
                                    itemCount: pageItems.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, i) {
                                      final u = pageItems[i];
                                      final isSelf = u.id == current.id;
                                      return UserCard(
                                        user: u,
                                        isSelf: isSelf,
                                        onEdit: () async {
                                          try {
                                            await _openEditDialog(
                                              user: u,
                                              currentAdminId: current.id,
                                              isSelf: isSelf,
                                            );
                                          } on AuthException catch (e) {
                                            _snack(e.message, error: true);
                                          }
                                        },
                                        onToggle: () =>
                                            _toggleActive(u, current.id),
                                        onDelete: () =>
                                            _deleteUser(u, current.id),
                                      );
                                    },
                                  )
                                : UserTable(
                                    users: pageItems,
                                    currentUserId: current.id,
                                    formatDate: _fmt,
                                    onEdit: (u) async {
                                      try {
                                        await _openEditDialog(
                                          user: u,
                                          currentAdminId: current.id,
                                          isSelf: u.id == current.id,
                                        );
                                      } on AuthException catch (e) {
                                        _snack(e.message, error: true);
                                      }
                                    },
                                    onToggleActive: (u) =>
                                        _toggleActive(u, current.id),
                                    onDelete: (u) =>
                                        _deleteUser(u, current.id),
                                  ),
                    ),
                    if (filtered.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: pageIndex > 0
                                  ? () => setState(() => _page = pageIndex - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                              color: HesapixColors.primary,
                            ),
                            Text(
                              'Sayfa ${pageIndex + 1} / $totalPages · ${filtered.length} kayıt',
                              style: const TextStyle(
                                fontSize: 13,
                                color: HesapixColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              onPressed: pageIndex < maxPageIndex
                                  ? () => setState(() => _page = pageIndex + 1)
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                              color: HesapixColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _pageHeader({required bool isNarrow}) {
    return isNarrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Kullanıcı Yönetimi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: HesapixColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sistemdeki kullanıcıları yönetin',
                style: TextStyle(
                  fontSize: 13,
                  color: HesapixColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await _openCreateDialog();
                  } on AuthException catch (e) {
                    _snack(e.message, error: true);
                  }
                },
                icon: const Icon(Icons.person_add_alt_1, size: 20),
                label: const Text('Yeni Kullanıcı'),
                style: FilledButton.styleFrom(
                  backgroundColor: HesapixColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kullanıcı Yönetimi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: HesapixColors.primary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sistemdeki kullanıcıları yönetin',
                      style: TextStyle(
                        fontSize: 14,
                        color: HesapixColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await _openCreateDialog();
                  } on AuthException catch (e) {
                    _snack(e.message, error: true);
                  }
                },
                icon: const Icon(Icons.person_add_alt_1, size: 20),
                label: const Text('Yeni Kullanıcı'),
                style: FilledButton.styleFrom(
                  backgroundColor: HesapixColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Henüz kullanıcı yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yeni kullanıcı ekleyerek başlayın',
            style: TextStyle(color: HesapixColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _noResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Sonuç bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Arama veya filtreleri değiştirmeyi deneyin',
            style: TextStyle(color: HesapixColors.textMuted),
          ),
        ],
      ),
    );
  }
}
