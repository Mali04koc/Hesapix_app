// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'urun.g.dart';

@JsonSerializable()
class Urun {
  const Urun({
    required this.isim,
    required this.satisFiyat,
    this.id,
    this.urunId,
    this.alisFiyat,
    this.stok,
    this.barkod,
    this.urunKodu,
  });
  
  factory Urun.fromJson(Map<String, Object?> json) => _$UrunFromJson(json);
  
  final String? id;
  final int? urunId;
  final String isim;
  final double? alisFiyat;
  final double satisFiyat;
  final int? stok;
  final String? barkod;
  final String? urunKodu;

  Map<String, Object?> toJson() => _$UrunToJson(this);
}
