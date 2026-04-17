import 'package:json_annotation/json_annotation.dart';
import '../../../core/utils/json_utils.dart';

part 'putaway_order.g.dart';

@JsonSerializable()
class PutawayOrder {
  final int? id;
  @JsonKey(name: 'putAwayNo')
  final String putAwayNo;
  @JsonKey(name: 'receiptNo')
  final String? receiptNo;
  @JsonKey(name: 'description')
  final String? description;
  @JsonKey(name: 'tenantId')
  final int tenantId;
  @JsonKey(name: 'transDate')
  final DateTime? transDate;
  @JsonKey(name: 'documentDate')
  final DateTime? documentDate;
  @JsonKey(name: 'documentNo')
  final String? documentNo;
  @JsonKey(name: 'location')
  final String? location;
  @JsonKey(name: 'postedDate')
  final DateTime? postedDate;
  @JsonKey(name: 'postedBy')
  final String? postedBy;
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

  final String? productName;
  final int? scanStatus; // -1: not scanned, 1: scanned, 3: handled by other

  PutawayOrder({
    this.id,
    required this.putAwayNo,
    this.receiptNo,
    this.description,
    required this.tenantId,
    this.transDate,
    this.documentDate,
    this.documentNo,
    this.location,
    this.postedDate,
    this.postedBy,
    required this.status,
    this.hhtStatus,
    this.hhtInfo,
    this.isDeleted = false,
    this.createAt,
    this.updateAt,
    this.productName,
    this.scanStatus,
  });

  factory PutawayOrder.fromJson(Map<String, dynamic> json) {
    return PutawayOrder(
      id: toInt(json['id']),
      putAwayNo: (json['putAwayNo'] ?? '').toString(),
      receiptNo: json['receiptNo']?.toString(),
      description: json['description']?.toString(),
      tenantId: toInt(json['tenantId']) ?? 0,
      transDate: toDate(json['transDate']),
      documentDate: toDate(json['documentDate']),
      documentNo: json['documentNo']?.toString(),
      location: json['location']?.toString(),
      postedDate: toDate(json['postedDate']),
      postedBy: json['postedBy']?.toString(),
      status: toInt(json['status']) ?? 0,
      hhtStatus: toInt(json['hhtStatus']),
      hhtInfo: json['hhtInfo']?.toString(),
      isDeleted: toBool(json['isDeleted']) ?? false,
      createAt: toDate(json['createAt']),
      updateAt: toDate(json['updateAt']),
      productName: json['productName']?.toString(),
      scanStatus: toInt(json['scanStatus']),
    );
  }

  Map<String, dynamic> toJson() => _$PutawayOrderToJson(this);

  PutawayOrder copyWith({
    int? id,
    String? putAwayNo,
    String? receiptNo,
    String? description,
    int? tenantId,
    DateTime? transDate,
    DateTime? documentDate,
    String? documentNo,
    String? location,
    DateTime? postedDate,
    String? postedBy,
    int? status,
    int? hhtStatus,
    String? hhtInfo,
    bool? isDeleted,
    DateTime? createAt,
    DateTime? updateAt,
    String? productName,
    int? scanStatus,
  }) {
    return PutawayOrder(
      id: id ?? this.id,
      putAwayNo: putAwayNo ?? this.putAwayNo,
      receiptNo: receiptNo ?? this.receiptNo,
      description: description ?? this.description,
      tenantId: tenantId ?? this.tenantId,
      transDate: transDate ?? this.transDate,
      documentDate: documentDate ?? this.documentDate,
      documentNo: documentNo ?? this.documentNo,
      location: location ?? this.location,
      postedDate: postedDate ?? this.postedDate,
      postedBy: postedBy ?? this.postedBy,
      status: status ?? this.status,
      hhtStatus: hhtStatus ?? this.hhtStatus,
      hhtInfo: hhtInfo ?? this.hhtInfo,
      isDeleted: isDeleted ?? this.isDeleted,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      productName: productName ?? this.productName,
      scanStatus: scanStatus ?? this.scanStatus,
    );
  }
}

