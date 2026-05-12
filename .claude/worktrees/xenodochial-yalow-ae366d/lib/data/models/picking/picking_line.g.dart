// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'picking_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PickingLine _$PickingLineFromJson(Map<String, dynamic> json) => PickingLine(
      id: (json['id'] as num?)?.toInt(),
      pickNo: json['pickNo'] as String,
      productCode: json['productCode'] as String,
      location: json['location'] as String?,
      bin: json['bin'] as String?,
      lotNo: json['lotNo'] as String?,
      pickQty: (json['pickQty'] as num).toDouble(),
      actualQty: (json['actualQty'] as num?)?.toDouble(),
      unitId: (json['unitId'] as num?)?.toInt(),
      status: (json['status'] as num).toInt(),
      isDeleted: json['isDeleted'] as bool? ?? false,
      shipmentLineId: (json['shipmentLineId'] as num?)?.toInt(),
      createAt: json['createAt'] == null
          ? null
          : DateTime.parse(json['createAt'] as String),
      updateAt: json['updateAt'] == null
          ? null
          : DateTime.parse(json['updateAt'] as String),
      productName: json['productName'] as String?,
      unitName: json['unitName'] as String?,
    );

Map<String, dynamic> _$PickingLineToJson(PickingLine instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pickNo': instance.pickNo,
      'productCode': instance.productCode,
      'location': instance.location,
      'bin': instance.bin,
      'lotNo': instance.lotNo,
      'pickQty': instance.pickQty,
      'actualQty': instance.actualQty,
      'unitId': instance.unitId,
      'status': instance.status,
      'isDeleted': instance.isDeleted,
      'shipmentLineId': instance.shipmentLineId,
      'createAt': instance.createAt?.toIso8601String(),
      'updateAt': instance.updateAt?.toIso8601String(),
      'productName': instance.productName,
      'unitName': instance.unitName,
    };
