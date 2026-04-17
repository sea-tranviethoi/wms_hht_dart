import 'package:json_annotation/json_annotation.dart';
import '../../../core/utils/json_utils.dart';

part 'picking_line.g.dart';

@JsonSerializable()
class PickingLine {
  final int? id;
  @JsonKey(name: 'pickNo')
  final String pickNo;
  @JsonKey(name: 'productCode')
  final String productCode;
  @JsonKey(name: 'location')
  final String? location;
  @JsonKey(name: 'bin')
  final String? bin;
  @JsonKey(name: 'lotNo')
  final String? lotNo;
  @JsonKey(name: 'pickQty')
  final double pickQty;
  @JsonKey(name: 'actualQty')
  final double? actualQty;
  @JsonKey(name: 'unitId')
  final int? unitId;
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

  final String? productName;
  final String? unitName;

  PickingLine({
    this.id,
    required this.pickNo,
    required this.productCode,
    this.location,
    this.bin,
    this.lotNo,
    required this.pickQty,
    this.actualQty,
    this.unitId,
    required this.status,
    this.isDeleted = false,
    this.shipmentLineId,
    this.createAt,
    this.updateAt,
    this.productName,
    this.unitName,
  });

  factory PickingLine.fromJson(Map<String, dynamic> json) {
    return PickingLine(
      id: toInt(json['id']),
      pickNo: (json['pickNo'] ?? '').toString(),
      productCode: (json['productCode'] ?? '').toString(),
      location: json['location']?.toString(),
      bin: json['bin']?.toString(),
      lotNo: json['lotNo']?.toString(),
      pickQty: toDouble(json['pickQty']) ?? 0.0,
      actualQty: toDouble(json['actualQty']),
      unitId: toInt(json['unitId']),
      status: toInt(json['status']) ?? 0,
      isDeleted: toBool(json['isDeleted']) ?? false,
      shipmentLineId: toInt(json['shipmentLineId']),
      createAt: toDate(json['createAt']),
      updateAt: toDate(json['updateAt']),
      productName: json['productName']?.toString(),
      unitName: json['unitName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$PickingLineToJson(this);

  PickingLine copyWith({
    int? id,
    String? pickNo,
    String? productCode,
    String? location,
    String? bin,
    String? lotNo,
    double? pickQty,
    double? actualQty,
    int? unitId,
    int? status,
    bool? isDeleted,
    int? shipmentLineId,
    DateTime? createAt,
    DateTime? updateAt,
    String? productName,
    String? unitName,
  }) {
    return PickingLine(
      id: id ?? this.id,
      pickNo: pickNo ?? this.pickNo,
      productCode: productCode ?? this.productCode,
      location: location ?? this.location,
      bin: bin ?? this.bin,
      lotNo: lotNo ?? this.lotNo,
      pickQty: pickQty ?? this.pickQty,
      actualQty: actualQty ?? this.actualQty,
      unitId: unitId ?? this.unitId,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      shipmentLineId: shipmentLineId ?? this.shipmentLineId,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      productName: productName ?? this.productName,
      unitName: unitName ?? this.unitName,
    );
  }
}

