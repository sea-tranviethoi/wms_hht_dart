// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bundle_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************


BundleLine _$BundleLineFromJson(Map<String, dynamic> json) => BundleLine(
    id: json['id']?.toString(),
    transNo: (json['transNo'] ?? '').toString(),
    productCode: (json['productCode'] ?? '').toString(),
    productName: json['productName']?.toString(),
    bin: json['bin']?.toString(),
    lotNo: json['lotNo']?.toString(),
    demandQty: (json['demandQty'] as num?)?.toDouble() ?? 0.0,
    actualQty: (json['actualQty'] as num?)?.toDouble() ?? 0.0,
    status: json['status'] as int? ?? 0,
    expirationDate: json['expirationDate']?.toString(),
    location: json['location']?.toString(),
    unitId: json['unitId'] as int?,
    isDeleted: json['isDeleted'] as bool? ?? false,
    createAt: json['createAt'] == null ? null : DateTime.parse(json['createAt'] as String),
    updateAt: json['updateAt'] == null ? null : DateTime.parse(json['updateAt'] as String),
  );

Map<String, dynamic> _$BundleLineToJson(BundleLine instance) => <String, dynamic>{
      'id': instance.id,
      'transNo': instance.transNo,
      'productCode': instance.productCode,
      'productName': instance.productName,
      'bin': instance.bin,
      'lotNo': instance.lotNo,
      'demandQty': instance.demandQty,
      'actualQty': instance.actualQty,
      'status': instance.status,
      'expirationDate': instance.expirationDate,
      'location': instance.location,
      'unitId': instance.unitId,
      'isDeleted': instance.isDeleted,
      'createAt': instance.createAt?.toIso8601String(),
      'updateAt': instance.updateAt?.toIso8601String(),
    };
