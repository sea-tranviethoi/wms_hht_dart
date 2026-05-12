import '../../../core/utils/json_utils.dart';

/// Dòng chi tiết của lệnh di chuyển bin
class InventTransferLine {
  final int? id;
  final String transferNo;
  final String productCode;
  final String? productName;
  final int? unitId;
  final String? unitName;
  final double journalQty; // số lượng kế hoạch
  final double? transQty;  // số lượng thực tế (scanned)
  final String? fromBin;
  final String? toBin;
  final String? lotNo;
  final String? expirationDate;
  final int status;
  final int? hhtStatus;
  final String? hhtInfo;
  final bool isDeleted;
  final DateTime? createAt;
  final DateTime? updateAt;

  InventTransferLine({
    this.id,
    required this.transferNo,
    required this.productCode,
    this.productName,
    this.unitId,
    this.unitName,
    required this.journalQty,
    this.transQty,
    this.fromBin,
    this.toBin,
    this.lotNo,
    this.expirationDate,
    this.status = 0,
    this.hhtStatus,
    this.hhtInfo,
    this.isDeleted = false,
    this.createAt,
    this.updateAt,
  });

  factory InventTransferLine.fromJson(Map<String, dynamic> json) {
    return InventTransferLine(
      id: toInt(json['id']),
      transferNo: (json['transferNo'] ?? json['transNo'] ?? '').toString(),
      productCode: (json['productCode'] ?? '').toString(),
      productName: json['productName']?.toString(),
      unitId: toInt(json['unitId']),
      unitName: json['unitName']?.toString(),
      journalQty: toDouble(json['journalQty']) ??
          toDouble(json['qty']) ??
          toDouble(json['quantity']) ??
          0.0,
      transQty: toDouble(json['transQty']),
      fromBin: json['fromBin']?.toString() ?? json['fromLocation']?.toString(),
      toBin: json['toBin']?.toString() ?? json['toLocation']?.toString(),
      lotNo: json['lotNo']?.toString(),
      expirationDate: json['expirationDate']?.toString() ??
          json['expiryDate']?.toString(),
      status: toInt(json['status']) ?? 0,
      hhtStatus: toInt(json['hhtStatus']),
      hhtInfo: json['hhtInfo']?.toString(),
      isDeleted: toBool(json['isDeleted']) ?? false,
      createAt: toDate(json['createAt']),
      updateAt: toDate(json['updateAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transferNo': transferNo,
        'productCode': productCode,
        'productName': productName,
        'unitId': unitId,
        'unitName': unitName,
        'journalQty': journalQty,
        'transQty': transQty,
        'fromBin': fromBin,
        'toBin': toBin,
        'lotNo': lotNo,
        'expirationDate': expirationDate,
        'status': status,
        'hhtStatus': hhtStatus,
        'hhtInfo': hhtInfo,
        'isDeleted': isDeleted,
        'createAt': createAt?.toIso8601String(),
        'updateAt': updateAt?.toIso8601String(),
      };

  InventTransferLine copyWith({
    int? id,
    String? transferNo,
    String? productCode,
    String? productName,
    int? unitId,
    String? unitName,
    double? journalQty,
    double? transQty,
    String? fromBin,
    String? toBin,
    String? lotNo,
    String? expirationDate,
    int? status,
    int? hhtStatus,
    String? hhtInfo,
    bool? isDeleted,
    DateTime? createAt,
    DateTime? updateAt,
  }) {
    return InventTransferLine(
      id: id ?? this.id,
      transferNo: transferNo ?? this.transferNo,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      journalQty: journalQty ?? this.journalQty,
      transQty: transQty ?? this.transQty,
      fromBin: fromBin ?? this.fromBin,
      toBin: toBin ?? this.toBin,
      lotNo: lotNo ?? this.lotNo,
      expirationDate: expirationDate ?? this.expirationDate,
      status: status ?? this.status,
      hhtStatus: hhtStatus ?? this.hhtStatus,
      hhtInfo: hhtInfo ?? this.hhtInfo,
      isDeleted: isDeleted ?? this.isDeleted,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
    );
  }
}
