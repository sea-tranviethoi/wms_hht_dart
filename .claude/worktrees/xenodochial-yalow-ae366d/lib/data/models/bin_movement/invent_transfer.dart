import '../../../core/utils/json_utils.dart';

/// Header của một lệnh di chuyển bin (棚移動)
class InventTransfer {
  final int? id;
  final String transferNo;
  final String? description;
  final int tenantId;
  final String? fromBin;
  final String? toBin;
  final int status; // 0 = pending
  final int? hhtStatus;
  final String? hhtInfo;
  final bool isDeleted;
  final DateTime? createAt;
  final DateTime? updateAt;

  // UI-only (enriched client-side)
  final String? productNames;
  final int? scanStatus; // -1: chưa xử lý, 1: máy này, 3: máy khác

  InventTransfer({
    this.id,
    required this.transferNo,
    this.description,
    required this.tenantId,
    this.fromBin,
    this.toBin,
    required this.status,
    this.hhtStatus,
    this.hhtInfo,
    this.isDeleted = false,
    this.createAt,
    this.updateAt,
    this.productNames,
    this.scanStatus,
  });

  factory InventTransfer.fromJson(Map<String, dynamic> json) {
    return InventTransfer(
      id: toInt(json['id']),
      transferNo: (json['transferNo'] ?? json['transNo'] ?? '').toString(),
      description: json['description']?.toString(),
      tenantId: toInt(json['tenantId']) ?? 0,
      fromBin: json['fromBin']?.toString() ?? json['fromLocation']?.toString(),
      toBin: json['toBin']?.toString() ?? json['toLocation']?.toString(),
      status: toInt(json['status']) ?? 0,
      hhtStatus: toInt(json['hhtStatus']),
      hhtInfo: json['hhtInfo']?.toString(),
      isDeleted: toBool(json['isDeleted']) ?? false,
      createAt: toDate(json['createAt']),
      updateAt: toDate(json['updateAt']),
      productNames: json['productNames']?.toString(),
      scanStatus: toInt(json['scanStatus']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transferNo': transferNo,
        'description': description,
        'tenantId': tenantId,
        'fromBin': fromBin,
        'toBin': toBin,
        'status': status,
        'hhtStatus': hhtStatus,
        'hhtInfo': hhtInfo,
        'isDeleted': isDeleted,
        'createAt': createAt?.toIso8601String(),
        'updateAt': updateAt?.toIso8601String(),
      };

  InventTransfer copyWith({
    int? id,
    String? transferNo,
    String? description,
    int? tenantId,
    String? fromBin,
    String? toBin,
    int? status,
    int? hhtStatus,
    String? hhtInfo,
    bool? isDeleted,
    DateTime? createAt,
    DateTime? updateAt,
    String? productNames,
    int? scanStatus,
  }) {
    return InventTransfer(
      id: id ?? this.id,
      transferNo: transferNo ?? this.transferNo,
      description: description ?? this.description,
      tenantId: tenantId ?? this.tenantId,
      fromBin: fromBin ?? this.fromBin,
      toBin: toBin ?? this.toBin,
      status: status ?? this.status,
      hhtStatus: hhtStatus ?? this.hhtStatus,
      hhtInfo: hhtInfo ?? this.hhtInfo,
      isDeleted: isDeleted ?? this.isDeleted,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      productNames: productNames ?? this.productNames,
      scanStatus: scanStatus ?? this.scanStatus,
    );
  }
}
