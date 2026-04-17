import 'package:json_annotation/json_annotation.dart';
import '../../../core/utils/json_utils.dart';

part 'putaway_staging.g.dart';

@JsonSerializable()
class PutawayStaging {
  final int? id;
  @JsonKey(name: 'putAwayNo')
  final String putAwayNo;
  @JsonKey(name: 'productCode')
  final String productCode;
  @JsonKey(name: 'unit')
  final String? unit;
  @JsonKey(name: 'unitId')
  final int? unitId;
  @JsonKey(name: 'journalQty')
  final double journalQty;
  @JsonKey(name: 'transQty')
  final double transQty;
  @JsonKey(name: 'bin')
  final String bin;
  @JsonKey(name: 'status')
  final int status;
  @JsonKey(name: 'isDeleted')
  final bool isDeleted;
  @JsonKey(name: 'lotNo')
  final String? lotNo;
  @JsonKey(name: 'expiryDate')
  final String? expiryDate;
  @JsonKey(name: 'expirationDate')
  final String? expirationDate;
  @JsonKey(name: 'putAwayLineId')
  final int? putAwayLineId;
  @JsonKey(name: 'janCode')
  final String? janCode;
  @JsonKey(name: 'createAt')
  final DateTime? createAt;
  @JsonKey(name: 'updateAt')
  final DateTime? updateAt;

  PutawayStaging({
    this.id,
    required this.putAwayNo,
    required this.productCode,
    this.unit,
    this.unitId,
    required this.journalQty,
    required this.transQty,
    required this.bin,
    required this.status,
    this.isDeleted = false,
    this.lotNo,
    this.expiryDate,
    this.expirationDate,
    this.putAwayLineId,
    this.janCode,
    this.createAt,
    this.updateAt,
  });

  factory PutawayStaging.fromJson(Map<String, dynamic> json) {
    return PutawayStaging(
      id: toInt(json['id']),
      putAwayNo: (json['putAwayNo'] ?? '').toString(),
      productCode: (json['productCode'] ?? '').toString(),
      unit: json['unit']?.toString(),
      unitId: toInt(json['unitId']),
      journalQty: toDouble(json['journalQty']) ?? 0.0,
      transQty: toDouble(json['transQty']) ?? 0.0,
      bin: (json['bin'] ?? '').toString(),
      status: toInt(json['status']) ?? 0,
      isDeleted: toBool(json['isDeleted']) ?? false,
      lotNo: json['lotNo']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
      expirationDate: json['expirationDate']?.toString() ??
          json['expiryDate']?.toString(),
      putAwayLineId: toInt(json['putAwayLineId']),
      janCode: json['janCode']?.toString(),
      createAt: toDate(json['createAt']),
      updateAt: toDate(json['updateAt']),
    );
  }

  Map<String, dynamic> toJson() => _$PutawayStagingToJson(this);

  PutawayStaging copyWith({
    int? id,
    String? putAwayNo,
    String? productCode,
    String? unit,
    int? unitId,
    double? journalQty,
    double? transQty,
    String? bin,
    int? status,
    bool? isDeleted,
    String? lotNo,
    String? expiryDate,
    String? expirationDate,
    int? putAwayLineId,
    String? janCode,
    DateTime? createAt,
    DateTime? updateAt,
  }) {
    return PutawayStaging(
      id: id ?? this.id,
      putAwayNo: putAwayNo ?? this.putAwayNo,
      productCode: productCode ?? this.productCode,
      unit: unit ?? this.unit,
      unitId: unitId ?? this.unitId,
      journalQty: journalQty ?? this.journalQty,
      transQty: transQty ?? this.transQty,
      bin: bin ?? this.bin,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      lotNo: lotNo ?? this.lotNo,
      expiryDate: expiryDate ?? this.expiryDate,
      expirationDate: expirationDate ?? this.expirationDate,
      putAwayLineId: putAwayLineId ?? this.putAwayLineId,
      janCode: janCode ?? this.janCode,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
    );
  }
}

