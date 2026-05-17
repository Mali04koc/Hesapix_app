import 'package:hesapix_app/core/database/database_manager.dart';
import 'package:hesapix_app/services/interfaces/i_cari_service.dart';
import 'package:hesapix_app/services/firebase_cari_service.dart';
import 'package:hesapix_app/services/postgres/postgres_cari_service.dart';
import 'package:hesapix_app/services/dual/dual_urun_service.dart';
import 'package:hesapix_app/services/dual/dual_cari_service.dart';

import 'package:hesapix_app/services/interfaces/i_urun_service.dart';
import 'package:hesapix_app/services/firebase_urun_service.dart';
import 'package:hesapix_app/services/postgres/postgres_urun_service.dart';

class ServiceLocator {
  // Singleton nesneleri (Her seferinde baştan oluşturmamak için)
  static final FirebaseCariService _firebaseCari = FirebaseCariService();
  static final PostgresCariService _postgresCari = PostgresCariService();
  
  static final FirebaseUrunService _firebaseUrun = FirebaseUrunService();
  static final PostgresUrunService _postgresUrun = PostgresUrunService();

  static final ICariService _dualCariService = DualCariService(
    firebaseService: _firebaseCari,
    postgresService: _postgresCari,
  );

  static final IUrunService _dualUrunService = DualUrunService(
    firebaseService: _firebaseUrun,
    postgresService: _postgresUrun,
  );

  static ICariService get cariService => _dualCariService;

  static IUrunService get urunService => _dualUrunService;
}
