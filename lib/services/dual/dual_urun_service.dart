import 'package:hesapix_app/models/urun_model.dart';
import 'package:hesapix_app/services/interfaces/i_urun_service.dart';
import 'package:hesapix_app/core/database/database_manager.dart';

class DualUrunService implements IUrunService {
  final IUrunService firebaseService;
  final IUrunService postgresService;

  DualUrunService({
    required this.firebaseService,
    required this.postgresService,
  });

  IUrunService get _activeService {
    return DatabaseManager().isFirebase
        ? firebaseService
        : postgresService;
  }

  @override
  Future<void> addUrun(Urun urun) async {
    await Future.wait([
      firebaseService.addUrun(urun),
      postgresService.addUrun(urun),
    ]);
  }

  @override
  Future<void> updateUrun(Urun urun) async {
    await Future.wait([
      firebaseService.updateUrun(urun),
      postgresService.updateUrun(urun),
    ]);
  }

  @override
  Future<void> deleteUrun(String id) async {
    await Future.wait([
      firebaseService.deleteUrun(id),
      postgresService.deleteUrun(id),
    ]);
  }

  @override
  Future<void> decreaseStock(String urunId, int miktar) async {
    await Future.wait([
      firebaseService.decreaseStock(urunId, miktar),
      postgresService.decreaseStock(urunId, miktar),
    ]);
  }

  @override
  Future<void> increaseStockByUrunId(int urunId, int miktar) async {
    await Future.wait([
      firebaseService.increaseStockByUrunId(urunId, miktar),
      postgresService.increaseStockByUrunId(urunId, miktar),
    ]);
  }

  @override
  Stream<List<Urun>> getUrunler() {
    return _activeService.getUrunler();
  }

  @override
  Future<List<Urun>> urunAra(String arama) {
    return _activeService.urunAra(arama);
  }
}
