// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'urun.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Urun _$UrunFromJson(Map<String, dynamic> json) => Urun(
  isim: json['isim'] as String,
  satisFiyat: (json['satisFiyat'] as num).toDouble(),
  id: json['id'] as String?,
  urunId: (json['urunId'] as num?)?.toInt(),
  alisFiyat: (json['alisFiyat'] as num?)?.toDouble(),
  stok: (json['stok'] as num?)?.toInt(),
  barkod: json['barkod'] as String?,
  urunKodu: json['urunKodu'] as String?,
);

Map<String, dynamic> _$UrunToJson(Urun instance) => <String, dynamic>{
  'id': instance.id,
  'urunId': instance.urunId,
  'isim': instance.isim,
  'alisFiyat': instance.alisFiyat,
  'satisFiyat': instance.satisFiyat,
  'stok': instance.stok,
  'barkod': instance.barkod,
  'urunKodu': instance.urunKodu,
};
