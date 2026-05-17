import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';
import 'package:hesapix_app/services/interfaces/i_cari_service.dart';
import 'package:hesapix_app/core/database/database_manager.dart';

class DualCariService implements ICariService {
  final ICariService firebaseService;
  final ICariService postgresService;

  DualCariService({
    required this.firebaseService,
    required this.postgresService,
  });

  ICariService get _activeService {
    return DatabaseManager().isFirebase
        ? firebaseService
        : postgresService;
  }

  @override
  Future<void> addCari(Cari cari) async {
    // Hem Firebase'e hem Postgres'e eşzamanlı yaz (Dual-Write)
    await Future.wait([
      firebaseService.addCari(cari),
      postgresService.addCari(cari),
    ]);
  }

  @override
  Future<void> updateCari(Cari cari) async {
    await Future.wait([
      firebaseService.updateCari(cari),
      postgresService.updateCari(cari),
    ]);
  }

  @override
  Future<void> deleteCari(String id) async {
    await Future.wait([
      firebaseService.deleteCari(id),
      postgresService.deleteCari(id),
    ]);
  }

  @override
  Future<void> addHareket(CariHareket hareket) async {
    await Future.wait([
      firebaseService.addHareket(hareket),
      postgresService.addHareket(hareket),
    ]);
  }

  // Okuma işlemleri sadece AKTİF veritabanından yapılır
  @override
  Stream<List<Cari>> getCariler() {
    return _activeService.getCariler();
  }

  @override
  Future<List<Cari>> cariAra(String arama) {
    return _activeService.cariAra(arama);
  }

  @override
  Stream<List<CariHareket>> getHareketler(String cariId) {
    return _activeService.getHareketler(cariId);
  }

  @override
  Stream<List<CariHareket>> getAllHareketler() {
    return _activeService.getAllHareketler();
  }
}
