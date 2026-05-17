import 'package:flutter_test/flutter_test.dart';
import 'package:hesapix_app/models/cari_model.dart';
import 'package:hesapix_app/pages/home/admin_home/satis_arayuz/satis_faturasi_odeme_page.dart';

import '../helpers/test_fixtures.dart';
import '../helpers/widget_test_harness.dart';

void main() {
  setUpAll(() async {
    await initWidgetTests();
  });

  group('SatisFaturasiOdemePage', () {
    testWidgets('ödeme ekranı temel bileşenleri gösterir', (tester) async {
      final cari = Cari(
        id: 'c1',
        cariKodu: 'C001',
        firmaAdi: 'Test Cari',
        vergiNo: '',
        mail: '',
        adres: '',
      );

      final sepet = [sampleSatisSepetItem(adet: 2, fiyat: 118.0)];

      await pumpApp(
        tester,
        SatisFaturasiOdemePage(cari: cari, sepet: sepet),
      );

      expect(find.text('Ödeme Ekranı'), findsOneWidget);
      expect(find.text('Nakit'), findsOneWidget);
      expect(find.text('Kredi Kartı'), findsOneWidget);
    });
  });
}
