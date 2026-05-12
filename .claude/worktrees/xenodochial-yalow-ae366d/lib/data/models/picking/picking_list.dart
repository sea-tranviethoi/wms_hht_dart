import 'package:json_annotation/json_annotation.dart';
import '../../../core/utils/json_utils.dart';

part 'picking_list.g.dart';

@JsonSerializable()
class PickingList {
  final int? id;
  @JsonKey(name: 'pickNo')
  final String pickNo;
  @JsonKey(name: 'tenantId')
  final int tenantId;
  @JsonKey(name: 'status')
  final int status;
  @JsonKey(name: 'hhtStatus')
  final int? hhtStatus;
  @JsonKey(name: 'hhtInfo')
  final String? hhtInfo;
  @JsonKey(name: 'isDeleted')
  final bool isDeleted;
  @JsonKey(name: 'createAt')
  final DateTime? createAt;
  @JsonKey(name: 'updateAt')
  final DateTime? updateAt;

  final int? binCount;
  final int? scanStatus; // 0: not scanned, 1: scanned, 2: handled by other

  PickingList({
    this.id,
    required this.pickNo,
    required this.tenantId,
    required this.status,
    this.hhtStatus,
    this.hhtInfo,
    this.isDeleted = false,
    this.createAt,
    this.updateAt,
    this.binCount,
    this.scanStatus,
  });

  factory PickingList.fromJson(Map<String, dynamic> json) {
    return PickingList(
      id: toInt(json['id']),
      pickNo: (json['pickNo'] ?? '').toString(),
      tenantId: toInt(json['tenantId']) ?? 0,
      status: toInt(json['status']) ?? 0,
      hhtStatus: toInt(json['hhtStatus']),
      hhtInfo: json['hhtInfo']?.toString(),
      isDeleted: toBool(json['isDeleted']) ?? false,
      createAt: toDate(json['createAt']),
      updateAt: toDate(json['updateAt']),
      binCount: toInt(json['binCount']),
      scanStatus: toInt(json['scanStatus']),
    );
  }

  Map<String, dynamic> toJson() => _$PickingListToJson(this);

  PickingList copyWith({
    int? id,
    String? pickNo,
    int? tenantId,
    int? status,
    int? hhtStatus,
    String? hhtInfo,
    bool? isDeleted,
    DateTime? createAt,
    DateTime? updateAt,
    int? binCount,
    int? scanStatus,
  }) {
    return PickingList(
      id: id ?? this.id,
      pickNo: pickNo ?? this.pickNo,
      tenantId: tenantId ?? this.tenantId,
      status: status ?? this.status,
      hhtStatus: hhtStatus ?? this.hhtStatus,
      hhtInfo: hhtInfo ?? this.hhtInfo,
      isDeleted: isDeleted ?? this.isDeleted,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      binCount: binCount ?? this.binCount,
      scanStatus: scanStatus ?? this.scanStatus,
    );
  }
}

