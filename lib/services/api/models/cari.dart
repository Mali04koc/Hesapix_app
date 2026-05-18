// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'cari.g.dart';

@JsonSerializable()
class Cari {
  const Cari({
    required this.unvan,
    this.id,
    this.telefon,
    this.bakiye,
    this.cariKodu,
  });
  
  factory Cari.fromJson(Map<String, Object?> json) => _$CariFromJson(json);
  
  final String? id;
  final String unvan;
  final String? telefon;
  final double? bakiye;
  final String? cariKodu;

  Map<String, Object?> toJson() => _$CariToJson(this);
}
