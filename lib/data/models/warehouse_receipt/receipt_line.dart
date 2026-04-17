import '../../../core/utils/json_utils.dart';

class ReceiptLine {
  final int? id;
  final String receiptNo;
  final String productCode;
  final int? unitId;
  final String? unitName;
  final double orderQty;
  final double? transQty;
  final String? bin;
  final String? lotNo;
  final String? expirationDate;
  final double? putaway;
  final int status;
  final String? arrivalNo;
  final int? receiptLineIdParent;
  final String? janCode;
  final bool isDeleted;
  final DateTime? createAt;
  final DateTime? updateAt;
  final String? createOperatorId;
  final String? updateOperatorId;

  final String? productName;
  final List<String>? errorImages;

  ReceiptLine({
    this.id,
    required this.receiptNo,
    required this.productCode,
    this.unitId,
    this.unitName,
    required this.orderQty,
    this.transQty,
    this.bin,
    this.lotNo,
    this.expirationDate,
    this.putaway,
    this.status = 1,
    this.arrivalNo,
    this.receiptLineIdParent,
    this.janCode,
    this.isDeleted = false,
    this.createAt,
    this.updateAt,
    this.createOperatorId,
    this.updateOperatorId,
    this.productName,
    this.errorImages,
  });

  factory ReceiptLine.fromJson(Map<String, dynamic> json) {
    return ReceiptLine(
      id: toInt(json['id']),
      receiptNo: (json['receiptNo'] ?? '').toString(),
      productCode: (json['productCode'] ?? '').toString(),
      unitId: toInt(json['unitId']),
      unitName: json['unitName']?.toString(),
      orderQty: toDouble(json['orderQty']) ?? 0,
      transQty: toDouble(json['transQty']),
      bin: json['bin']?.toString(),
      lotNo: json['lotNo']?.toString(),
      expirationDate: json['expirationDate']?.toString(),
      putaway: toDouble(json['putaway']),
      status: toInt(json['status']) ?? 1,
      arrivalNo: json['arrivalNo']?.toString(),
      receiptLineIdParent: toInt(json['receiptLineIdParent']),
      janCode: json['janCode']?.toString(),
      isDeleted: toBool(json['isDeleted']) ?? false,
      createAt: toDate(json['createAt']),
      updateAt: toDate(json['updateAt']),
      createOperatorId: json['createOperatorId']?.toString(),
      updateOperatorId: json['updateOperatorId']?.toString(),
      productName: json['productName']?.toString(),
      errorImages: (json['errorImages'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiptNo': receiptNo,
        'productCode': productCode,
        'unitId': unitId,
        'unitName': unitName,
        'orderQty': orderQty,
        'transQty': transQty,
        'bin': bin,
        'lotNo': lotNo,
        'expirationDate': expirationDate,
        'putaway': putaway,
        'status': status,
        'arrivalNo': arrivalNo,
        'receiptLineIdParent': receiptLineIdParent,
        'janCode': janCode,
        'isDeleted': isDeleted,
        'createAt': createAt?.toIso8601String(),
        'updateAt': updateAt?.toIso8601String(),
        'createOperatorId': createOperatorId,
        'updateOperatorId': updateOperatorId,
        'productName': productName,
        'errorImages': errorImages,
      };

  ReceiptLine copyWith({
    int? id,
    String? receiptNo,
    String? productCode,
    int? unitId,
    String? unitName,
    double? orderQty,
    double? transQty,
    String? bin,
    String? lotNo,
    String? expirationDate,
    double? putaway,
    int? status,
    String? arrivalNo,
    int? receiptLineIdParent,
    String? janCode,
    bool? isDeleted,
    DateTime? createAt,
    DateTime? updateAt,
    String? createOperatorId,
    String? updateOperatorId,
    String? productName,
    List<String>? errorImages,
  }) {
    return ReceiptLine(
      id: id ?? this.id,
      receiptNo: receiptNo ?? this.receiptNo,
      productCode: productCode ?? this.productCode,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      orderQty: orderQty ?? this.orderQty,
      transQty: transQty ?? this.transQty,
      bin: bin ?? this.bin,
      lotNo: lotNo ?? this.lotNo,
      expirationDate: expirationDate ?? this.expirationDate,
      putaway: putaway ?? this.putaway,
      status: status ?? this.status,
      arrivalNo: arrivalNo ?? this.arrivalNo,
      receiptLineIdParent: receiptLineIdParent ?? this.receiptLineIdParent,
      janCode: janCode ?? this.janCode,
      isDeleted: isDeleted ?? this.isDeleted,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      createOperatorId: createOperatorId ?? this.createOperatorId,
      updateOperatorId: updateOperatorId ?? this.updateOperatorId,
      productName: productName ?? this.productName,
      errorImages: errorImages ?? this.errorImages,
    );
  }
}



