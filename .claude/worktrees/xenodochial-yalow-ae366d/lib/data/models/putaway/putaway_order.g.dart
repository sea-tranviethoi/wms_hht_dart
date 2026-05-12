// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'putaway_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PutawayOrder _$PutawayOrderFromJson(Map<String, dynamic> json) => PutawayOrder(
      id: (json['id'] as num?)?.toInt(),
      putAwayNo: json['putAwayNo'] as String,
      receiptNo: json['receiptNo'] as String?,
      description: json['description'] as String?,
      tenantId: (json['tenantId'] as num).toInt(),
      transDate: json['transDate'] == null
          ? null
          : DateTime.parse(json['transDate'] as String),
      documentDate: json['documentDate'] == null
          ? null
          : DateTime.parse(json['documentDate'] as String),
      documentNo: json['documentNo'] as String?,
      location: json['location'] as String?,
      postedDate: json['postedDate'] == null
          ? null
          : DateTime.parse(json['postedDate'] as String),
      postedBy: json['postedBy'] as String?,
      status: (json['status'] as num).toInt(),
      hhtStatus: (json['hhtStatus'] as num?)?.toInt(),
      hhtInfo: json['hhtInfo'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createAt: json['createAt'] == null
          ? null
          : DateTime.parse(json['createAt'] as String),
      updateAt: json['updateAt'] == null
          ? null
          : DateTime.parse(json['updateAt'] as String),
      productName: json['productName'] as String?,
      scanStatus: (json['scanStatus'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PutawayOrderToJson(PutawayOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'putAwayNo': instance.putAwayNo,
      'receiptNo': instance.receiptNo,
      'description': instance.description,
      'tenantId': instance.tenantId,
      'transDate': instance.transDate?.toIso8601String(),
      'documentDate': instance.documentDate?.toIso8601String(),
      'documentNo': instance.documentNo,
      'location': instance.location,
      'postedDate': instance.postedDate?.toIso8601String(),
      'postedBy': instance.postedBy,
      'status': instance.status,
      'hhtStatus': instance.hhtStatus,
      'hhtInfo': instance.hhtInfo,
      'isDeleted': instance.isDeleted,
      'createAt': instance.createAt?.toIso8601String(),
      'updateAt': instance.updateAt?.toIso8601String(),
      'productName': instance.productName,
      'scanStatus': instance.scanStatus,
    };
