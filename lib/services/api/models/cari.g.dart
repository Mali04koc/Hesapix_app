// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cari.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Cari _$CariFromJson(Map<String, dynamic> json) => Cari(
  unvan: json['unvan'] as String,
  id: json['id'] as String?,
  telefon: json['telefon'] as String?,
  bakiye: (json['bakiye'] as num?)?.toDouble(),
  cariKodu: json['cariKodu'] as String?,
);

Map<String, dynamic> _$CariToJson(Cari instance) => <String, dynamic>{
  'id': instance.id,
  'unvan': instance.unvan,
  'telefon': instance.telefon,
  'bakiye': instance.bakiye,
  'cariKodu': instance.cariKodu,
};
