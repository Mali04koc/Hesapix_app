// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/cari.dart';
import '../models/urun.dart';

part 'fallback_client.g.dart';

@RestApi()
abstract class FallbackClient {
  factory FallbackClient(Dio dio, {String? baseUrl}) = _FallbackClient;

  /// Tüm ürünleri listele
  @GET('/urunler')
  Future<List<Urun>> getUrunler();

  /// Yeni ürün ekle.
  ///
  /// [body] - Eklenecek ürün bilgileri.
  @POST('/urunler')
  Future<Urun> addUrun({
    @Body() required Urun body,
  });

  /// ID ile ürün getir
  @GET('/urunler/{id}')
  Future<Urun> getUrunById({
    @Path('id') required String id,
  });

  /// Tüm cari hesapları listele
  @GET('/cariler')
  Future<List<Cari>> getCariler();
}
