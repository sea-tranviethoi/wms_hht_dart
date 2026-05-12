// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'picking_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PickingList _$PickingListFromJson(Map<String, dynamic> json) => PickingList(
      id: (json['id'] as num?)?.toInt(),
      pickNo: json['pickNo'] as String,
      tenantId: (json['tenantId'] as num).toInt(),
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
      binCount: (json['binCount'] as num?)?.toInt(),
      scanStatus: (json['scanStatus'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PickingListToJson(PickingList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pickNo': instance.pickNo,
      'tenantId': instance.tenantId,
      'status': instance.status,
      'hhtStatus': instance.hhtStatus,
      'hhtInfo': instance.hhtInfo,
      'isDeleted': instance.isDeleted,
      'createAt': instance.createAt?.toIso8601String(),
      'updateAt': instance.updateAt?.toIso8601String(),
      'binCount': instance.binCount,
      'scanStatus': instance.scanStatus,
    };
