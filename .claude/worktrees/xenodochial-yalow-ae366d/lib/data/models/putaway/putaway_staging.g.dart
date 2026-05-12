// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'putaway_staging.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PutawayStaging _$PutawayStagingFromJson(Map<String, dynamic> json) =>
    PutawayStaging(
      id: (json['id'] as num?)?.toInt(),
      putAwayNo: json['putAwayNo'] as String,
      productCode: json['productCode'] as String,
      unit: json['unit'] as String?,
      unitId: (json['unitId'] as num?)?.toInt(),
      journalQty: (json['journalQty'] as num).toDouble(),
      transQty: (json['transQty'] as num).toDouble(),
      bin: json['bin'] as String,
      status: (json['status'] as num).toInt(),
      isDeleted: json['isDeleted'] as bool? ?? false,
      lotNo: json['lotNo'] as String?,
      expiryDate: json['expiryDate'] as String?,
      expirationDate: json['expirationDate'] as String?,
      putAwayLineId: (json['putAwayLineId'] as num?)?.toInt(),
      janCode: json['janCode'] as String?,
      createAt: json['createAt'] == null
          ? null
          : DateTime.parse(json['createAt'] as String),
      updateAt: json['updateAt'] == null
          ? null
          : DateTime.parse(json['updateAt'] as String),
    );

Map<String, dynamic> _$PutawayStagingToJson(PutawayStaging instance) =>
    <String, dynamic>{
      'id': instance.id,
      'putAwayNo': instance.putAwayNo,
      'productCode': instance.productCode,
      'unit': instance.unit,
      'unitId': instance.unitId,
      'journalQty': instance.journalQty,
      'transQty': instance.transQty,
      'bin': instance.bin,
      'status': instance.status,
      'isDeleted': instance.isDeleted,
      'lotNo': instance.lotNo,
      'expiryDate': instance.expiryDate,
      'expirationDate': instance.expirationDate,
      'putAwayLineId': instance.putAwayLineId,
      'janCode': instance.janCode,
      'createAt': instance.createAt?.toIso8601String(),
      'updateAt': instance.updateAt?.toIso8601String(),
    };
