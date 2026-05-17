import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/models/cari_hareket_model.dart';

abstract class ICariService {
  Future<void> addCari(Cari cari);
  Future<List<Cari>> cariAra(String arama);
  Stream<List<Cari>> getCariler();
  Future<void> updateCari(Cari cari);
  Future<void> deleteCari(String id);
  
  Future<void> addHareket(CariHareket hareket);
  Stream<List<CariHareket>> getHareketler(String cariId);
  Stream<List<CariHareket>> getAllHareketler();
}
