import 'package:json_annotation/json_annotation.dart';
import '../../../core/utils/json_utils.dart';

part 'putaway_line.g.dart';

@JsonSerializable()
class PutawayLine {
  final int? id;
  @JsonKey(name: 'putAwayNo')
  final String putAwayNo;
  @JsonKey(name: 'productCode')
  final String productCode;
  @JsonKey(name: 'unitId')
  final int unitId;
  @JsonKey(name: 'journalQty')
  final double journalQty;
  @JsonKey(name: 'transQty')
  final double? transQty;
  @JsonKey(name: 'bin')
  final String? bin;
  @JsonKey(name: 'status')
  final int status;
  @JsonKey(name: 'hhtStatus')
  final int? hhtStatus;
  @JsonKey(name: 'hhtInfo')
  final String? hhtInfo;
  @JsonKey(name: 'isDeleted')
  final bool isDeleted;
  @JsonKey(name: 'lotNo')
  final String? lotNo;
  @JsonKey(name: 'tenantId')
  final int? tenantId;
  @JsonKey(name: 'expirationDate')
  final String? expirationDate;
  @JsonKey(name: 'receiptLineId')
  final int? receiptLineId;
  @JsonKey(name: 'createAt')
  final DateTime? createAt;
  @JsonKey(name: 'updateAt')
  final DateTime? updateAt;

  final String? productName;
  final String? unitName;

  PutawayLine({
    this.id,
    required this.putAwayNo,
    required this.productCode,
    required this.unitId,
    required this.journalQty,
    this.transQty,
    this.bin,
    required this.status,
    this.hhtStatus,
    this.hhtInfo,
    this.isDeleted = false,
    this.lotNo,
    this.tenantId,
    this.expirationDate,
    this.receiptLineId,
    this.createAt,
    this.updateAt,
    this.productName,
    this.unitName,
  });

  factory PutawayLine.fromJson(Map<String, dynamic> json) {
    return PutawayLine(
      id: toInt(json['id']),
      putAwayNo: (json['putAwayNo'] ?? '').toString(),
      productCode: (json['productCode'] ?? '').toString(),
      unitId: toInt(json['unitId']) ?? 0,
      journalQty: toDouble(json['journalQty']) ?? 0.0,
      transQty: toDouble(json['transQty']),
      bin: json['bin']?.toString(),
      status: toInt(json['status']) ?? 0,
      hhtStatus: toInt(json['hhtStatus']),
      hhtInfo: json['hhtInfo']?.toString(),
      isDeleted: toBool(json['isDeleted']) ?? false,
      lotNo: json['lotNo']?.toString(),
      tenantId: toInt(json['tenantId']),
      expirationDate: json['expirationDate']?.toString() ??
          json['expiryDate']?.toString(),
      receiptLineId: toInt(json['receiptLineId']),
      createAt: toDate(json['createAt']),
      updateAt: toDate(json['updateAt']),
      productName: json['productName']?.toString(),
      unitName: json['unitName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$PutawayLineToJson(this);

  PutawayLine copyWith({
    int? id,
    String? putAwayNo,
    String? productCode,
    int? unitId,
    double? journalQty,
    double? transQty,
    String? bin,
    int? status,
    int? hhtStatus,
    String? hhtInfo,
    bool? isDeleted,
    String? lotNo,
    int? tenantId,
    String? expirationDate,
    int? receiptLineId,
    DateTime? createAt,
    DateTime? updateAt,
    String? productName,
    String? unitName,
  }) {
    return PutawayLine(
      id: id ?? this.id,
      putAwayNo: putAwayNo ?? this.putAwayNo,
      productCode: productCode ?? this.productCode,
      unitId: unitId ?? this.unitId,
      journalQty: journalQty ?? this.journalQty,
      transQty: transQty ?? this.transQty,
      bin: bin ?? this.bin,
      status: status ?? this.status,
      hhtStatus: hhtStatus ?? this.hhtStatus,
      hhtInfo: hhtInfo ?? this.hhtInfo,
      isDeleted: isDeleted ?? this.isDeleted,
      lotNo: lotNo ?? this.lotNo,
      tenantId: tenantId ?? this.tenantId,
      expirationDate: expirationDate ?? this.expirationDate,
      receiptLineId: receiptLineId ?? this.receiptLineId,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      productName: productName ?? this.productName,
      unitName: unitName ?? this.unitName,
    );
  }
}

