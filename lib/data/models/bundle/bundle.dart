import 'package:json_annotation/json_annotation.dart';
import '../../../core/utils/json_utils.dart';

part 'bundle.g.dart';

@JsonSerializable()
class Bundle {
  final int? id;
  @JsonKey(name: 'transNo')
  final String transNo;
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

  final int? countLine;
  final String? productName;
  final int? scanStatus; // 0: not scanned, 1: scanned, 2: handled by other

  Bundle({
    this.id,
    required this.transNo,
    required this.status,
    this.hhtStatus,
    this.hhtInfo,
    this.isDeleted = false,
    this.createAt,
    this.updateAt,
    this.countLine,
    this.productName,
    this.scanStatus,
  });

  factory Bundle.fromJson(Map<String, dynamic> json) {
    return Bundle(
      id: toInt(json['id']),
      transNo: (json['transNo'] ?? '').toString(),
      status: toInt(json['status']) ?? 0,
      hhtStatus: toInt(json['hhtStatus']),
      hhtInfo: json['hhtInfo']?.toString(),
      isDeleted: toBool(json['isDeleted']) ?? false,
      createAt: toDate(json['createAt']),
      updateAt: toDate(json['updateAt']),
      countLine: toInt(json['countLine']),
      productName: json['productName']?.toString(),
      scanStatus: toInt(json['scanStatus']),
    );
  }

  Map<String, dynamic> toJson() => _$BundleToJson(this);

  Bundle copyWith({
    int? id,
    String? transNo,
    int? status,
    int? hhtStatus,
    String? hhtInfo,
    bool? isDeleted,
    DateTime? createAt,
    DateTime? updateAt,
    int? countLine,
    String? productName,
    int? scanStatus,
  }) {
    return Bundle(
      id: id ?? this.id,
      transNo: transNo ?? this.transNo,
      status: status ?? this.status,
      hhtStatus: hhtStatus ?? this.hhtStatus,
      hhtInfo: hhtInfo ?? this.hhtInfo,
      isDeleted: isDeleted ?? this.isDeleted,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      countLine: countLine ?? this.countLine,
      productName: productName ?? this.productName,
      scanStatus: scanStatus ?? this.scanStatus,
    );
  }
}

