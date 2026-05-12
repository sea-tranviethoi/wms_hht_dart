// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'putaway_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PutawayLine _$PutawayLineFromJson(Map<String, dynamic> json) => PutawayLine(
      id: (json['id'] as num?)?.toInt(),
      putAwayNo: json['putAwayNo'] as String,
      productCode: json['productCode'] as String,
      unitId: (json['unitId'] as num).toInt(),
      journalQty: (json['journalQty'] as num).toDouble(),
      transQty: (json['transQty'] as num?)?.toDouble(),
      bin: json['bin'] as String?,
      status: (json['status'] as num).toInt(),
      hhtStatus: (json['hhtStatus'] as num?)?.toInt(),
      hhtInfo: json['hhtInfo'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      lotNo: json['lotNo'] as String?,
      tenantId: (json['tenantId'] as num?)?.toInt(),
      expirationDate: json['expirationDate'] as String?,
      receiptLineId: (json['receiptLineId'] as num?)?.toInt(),
      createAt: json['createAt'] == null
          ? null
          : DateTime.parse(json['createAt'] as String),
      updateAt: json['updateAt'] == null
          ? null
          : DateTime.parse(json['updateAt'] as String),
      productName: json['productName'] as String?,
      unitName: json['unitName'] as String?,
    );

Map<String, dynamic> _$PutawayLineToJson(PutawayLine instance) =>
    <String, dynamic>{
      'id': instance.id,
      'putAwayNo': instance.putAwayNo,
      'productCode': instance.productCode,
      'unitId': instance.unitId,
      'journalQty': instance.journalQty,
      'transQty': instance.transQty,
      'bin': instance.bin,
      'status': instance.status,
      'hhtStatus': instance.hhtStatus,
      'hhtInfo': instance.hhtInfo,
      'isDeleted': instance.isDeleted,
      'lotNo': instance.lotNo,
      'tenantId': instance.tenantId,
      'expirationDate': instance.expirationDate,
      'receiptLineId': instance.receiptLineId,
      'createAt': instance.createAt?.toIso8601String(),
      'updateAt': instance.updateAt?.toIso8601String(),
      'productName': instance.productName,
      'unitName': instance.unitName,
    };
