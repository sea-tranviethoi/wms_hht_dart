// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'picking_staging.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PickingStaging _$PickingStagingFromJson(Map<String, dynamic> json) =>
    PickingStaging(
      id: (json['id'] as num?)?.toInt(),
      pickNo: json['pickNo'] as String,
      productCode: json['productCode'] as String,
      unit: json['unit'] as String?,
      unitId: (json['unitId'] as num?)?.toInt(),
      location: json['location'] as String?,
      bin: json['bin'] as String?,
      lotNo: json['lotNo'] as String?,
      pickQty: (json['pickQty'] as num).toDouble(),
      actualQty: (json['actualQty'] as num).toDouble(),
      status: (json['status'] as num).toInt(),
      isDeleted: json['isDeleted'] as bool? ?? false,
      shipmentLineId: (json['shipmentLineId'] as num?)?.toInt(),
      createAt: json['createAt'] == null
          ? null
          : DateTime.parse(json['createAt'] as String),
      updateAt: json['updateAt'] == null
          ? null
          : DateTime.parse(json['updateAt'] as String),
    );

Map<String, dynamic> _$PickingStagingToJson(PickingStaging instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pickNo': instance.pickNo,
      'productCode': instance.productCode,
      'unit': instance.unit,
      'unitId': instance.unitId,
      'location': instance.location,
      'bin': instance.bin,
      'lotNo': instance.lotNo,
      'pickQty': instance.pickQty,
      'actualQty': instance.actualQty,
      'status': instance.status,
      'isDeleted': instance.isDeleted,
      'shipmentLineId': instance.shipmentLineId,
      'createAt': instance.createAt?.toIso8601String(),
      'updateAt': instance.updateAt?.toIso8601String(),
    };
