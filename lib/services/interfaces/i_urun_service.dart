import 'package:hesapix_app/models/urun_model.dart';

abstract class IUrunService {
  Future<void> addUrun(Urun urun);
  Stream<List<Urun>> getUrunler();
  Future<void> updateUrun(Urun urun);
  Future<void> deleteUrun(String id);
  Future<void> decreaseStock(String urunId, int miktar);
  Future<void> increaseStockByUrunId(int urunId, int miktar);
  Future<List<Urun>> urunAra(String arama);
}
