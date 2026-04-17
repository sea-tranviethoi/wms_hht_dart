import '../../../core/utils/json_utils.dart';

class ReceiptOrder {
  final int? id;
  final String receiptNo;
  final int supplierId;
  final int tenantId;
  final int status;
  final int? hhtStatus;
  final String? hhtInfo;
  final String? scheduledArrivalNumber;
  final bool isDeleted;
  final DateTime? createAt;
  final DateTime? updateAt;

  final String? supplierName;
  final String? productNames;
  final int? scanStatus; // -1: not scanned, 2: scanned, 3: handled by other

  ReceiptOrder({
    this.id,
    required this.receiptNo,
    required this.supplierId,
    required this.tenantId,
    required this.status,
    this.hhtStatus,
    this.hhtInfo,
    this.scheduledArrivalNumber,
    this.isDeleted = false,
    this.createAt,
    this.updateAt,
    this.supplierName,
    this.productNames,
    this.scanStatus,
  });

  factory ReceiptOrder.fromJson(Map<String, dynamic> json) {
    return ReceiptOrder(
      id: toInt(json['id']),
      receiptNo: (json['receiptNo'] ?? '').toString(),
      supplierId: toInt(json['supplierId']) ?? 0,
      tenantId: toInt(json['tenantId']) ?? 0,
      status: toInt(json['status']) ?? 0,
      hhtStatus: toInt(json['hhtStatus']),
      hhtInfo: json['hhtInfo']?.toString(),
      scheduledArrivalNumber: json['scheduledArrivalNumber']?.toString(),
      isDeleted: toBool(json['isDeleted']) ?? false,
      createAt: toDate(json['createAt']),
      updateAt: toDate(json['updateAt']),
      supplierName: json['supplierName']?.toString(),
      productNames: json['productNames']?.toString(),
      scanStatus: toInt(json['scanStatus']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiptNo': receiptNo,
        'supplierId': supplierId,
        'tenantId': tenantId,
        'status': status,
        'hhtStatus': hhtStatus,
        'hhtInfo': hhtInfo,
        'scheduledArrivalNumber': scheduledArrivalNumber,
        'isDeleted': isDeleted,
        'createAt': createAt?.toIso8601String(),
        'updateAt': updateAt?.toIso8601String(),
        'supplierName': supplierName,
        'productNames': productNames,
        'scanStatus': scanStatus,
      };

  ReceiptOrder copyWith({
    int? id,
    String? receiptNo,
    int? supplierId,
    int? tenantId,
    int? status,
    int? hhtStatus,
    String? hhtInfo,
    String? scheduledArrivalNumber,
    bool? isDeleted,
    DateTime? createAt,
    DateTime? updateAt,
    String? supplierName,
    String? productNames,
    int? scanStatus,
  }) {
    return ReceiptOrder(
      id: id ?? this.id,
      receiptNo: receiptNo ?? this.receiptNo,
      supplierId: supplierId ?? this.supplierId,
      tenantId: tenantId ?? this.tenantId,
      status: status ?? this.status,
      hhtStatus: hhtStatus ?? this.hhtStatus,
      hhtInfo: hhtInfo ?? this.hhtInfo,
      scheduledArrivalNumber:
          scheduledArrivalNumber ?? this.scheduledArrivalNumber,
      isDeleted: isDeleted ?? this.isDeleted,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      supplierName: supplierName ?? this.supplierName,
      productNames: productNames ?? this.productNames,
      scanStatus: scanStatus ?? this.scanStatus,
    );
  }
}



