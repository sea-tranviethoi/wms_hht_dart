// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bundle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Bundle _$BundleFromJson(Map<String, dynamic> json) => Bundle(
      id: (json['id'] as num?)?.toInt(),
      transNo: json['transNo'] as String,
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
      countLine: (json['countLine'] as num?)?.toInt(),
      productName: json['productName'] as String?,
      scanStatus: (json['scanStatus'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BundleToJson(Bundle instance) => <String, dynamic>{
      'id': instance.id,
      'transNo': instance.transNo,
      'status': instance.status,
      'hhtStatus': instance.hhtStatus,
      'hhtInfo': instance.hhtInfo,
      'isDeleted': instance.isDeleted,
      'createAt': instance.createAt?.toIso8601String(),
      'updateAt': instance.updateAt?.toIso8601String(),
      'countLine': instance.countLine,
      'productName': instance.productName,
      'scanStatus': instance.scanStatus,
    };
