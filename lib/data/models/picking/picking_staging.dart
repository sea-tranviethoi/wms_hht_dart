import 'package:json_annotation/json_annotation.dart';
import '../../../core/utils/json_utils.dart';

part 'picking_staging.g.dart';

@JsonSerializable()
class PickingStaging {
  final int? id;
  @JsonKey(name: 'pickNo')
  final String pickNo;
  @JsonKey(name: 'productCode')
  final String productCode;
  @JsonKey(name: 'unit')
  final String? unit;
  @JsonKey(name: 'unitId')
  final int? unitId;
  @JsonKey(name: 'location')
  final String? location;
  @JsonKey(name: 'bin')
  final String? bin;
  @JsonKey(name: 'lotNo')
  final String? lotNo;
  @JsonKey(name: 'pickQty')
  final double pickQty;
  @JsonKey(name: 'actualQty')
  final double actualQty;
  @JsonKey(name: 'status')
  final int status;
  @JsonKey(name: 'isDeleted')
  final bool isDeleted;
  @JsonKey(name: 'shipmentLineId')
  final int? shipmentLineId;
  @JsonKey(name: 'createAt')
  final DateTime? createAt;
  @JsonKey(name: 'updateAt')
  final DateTime? updateAt;

  PickingStaging({
    this.id,
    required this.pickNo,
    required this.productCode,
    this.unit,
    this.unitId,
    this.location,
    this.bin,
    this.lotNo,
    required this.pickQty,
    required this.actualQty,
    required this.status,
    this.isDeleted = false,
    this.shipmentLineId,
    this.createAt,
    this.updateAt,
  });

  factory PickingStaging.fromJson(Map<String, dynamic> json) {
    return PickingStaging(
      id: toInt(json['id']),
      pickNo: (json['pickNo'] ?? '').toString(),
      productCode: (json['productCode'] ?? '').toString(),
      unit: json['unit']?.toString(),
      unitId: toInt(json['unitId']),
      location: json['location']?.toString(),
      bin: json['bin']?.toString(),
      lotNo: json['lotNo']?.toString(),
      pickQty: toDouble(json['pickQty']) ?? 0.0,
      actualQty: toDouble(json['actualQty']) ?? 0.0,
      status: toInt(json['status']) ?? 0,
      isDeleted: toBool(json['isDeleted']) ?? false,
      shipmentLineId: toInt(json['shipmentLineId']),
      createAt: toDate(json['createAt']),
      updateAt: toDate(json['updateAt']),
    );
  }

  Map<String, dynamic> toJson() => _$PickingStagingToJson(this);

  PickingStaging copyWith({
    int? id,
    String? pickNo,
    String? productCode,
    String? unit,
    int? unitId,
    String? location,
    String? bin,
    String? lotNo,
    double? pickQty,
    double? actualQty,
    int? status,
    bool? isDeleted,
    int? shipmentLineId,
    DateTime? createAt,
    DateTime? updateAt,
  }) {
    return PickingStaging(
      id: id ?? this.id,
      pickNo: pickNo ?? this.pickNo,
      productCode: productCode ?? this.productCode,
      unit: unit ?? this.unit,
      unitId: unitId ?? this.unitId,
      location: location ?? this.location,
      bin: bin ?? this.bin,
      lotNo: lotNo ?? this.lotNo,
      pickQty: pickQty ?? this.pickQty,
      actualQty: actualQty ?? this.actualQty,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      shipmentLineId: shipmentLineId ?? this.shipmentLineId,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
    );
  }
}

