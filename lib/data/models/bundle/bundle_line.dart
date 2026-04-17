
import '../../../core/utils/json_utils.dart';
part 'bundle_line.g.dart';

class BundleLine {
  final String? id;
  final String transNo;
  final String productCode;
  final String? productName;
  final String? bin;
  final String? lotNo;
  final double demandQty;
  final double actualQty;
  final int status;
  final String? expirationDate;
  final String? location;
  final int? unitId;
  final bool isDeleted;
  final DateTime? createAt;
  final DateTime? updateAt;

  BundleLine({
    this.id,
    required this.transNo,
    required this.productCode,
    this.productName,
    this.bin,
    this.lotNo,
    required this.demandQty,
    this.actualQty = 0.0,
    this.status = 0,
    this.expirationDate,
    this.location,
    this.unitId,
    this.isDeleted = false,
    this.createAt,
    this.updateAt,
  });

  factory BundleLine.fromJson(Map<String, dynamic> json) {
    return BundleLine(
      id: json['id']?.toString(),
      transNo: (json['transNo'] ?? '').toString(),
      productCode: (json['productCode'] ?? '').toString(),
      productName: json['productName']?.toString(),
      bin: json['bin']?.toString(),
      lotNo: json['lotNo']?.toString(),
      demandQty: toDouble(json['demandQty']) ?? 0.0,
      actualQty: toDouble(json['actualQty']) ?? 0.0,
      status: toInt(json['status']) ?? 0,
      expirationDate: json['expirationDate']?.toString(),
      location: json['location']?.toString(),
      unitId: toInt(json['unitId']),
      isDeleted: toBool(json['isDeleted']) ?? false,
      createAt: toDate(json['createAt']),
      updateAt: toDate(json['updateAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transNo': transNo,
      'productCode': productCode,
      'productName': productName,
      'bin': bin,
      'lotNo': lotNo,
      'demandQty': demandQty,
      'actualQty': actualQty,
      'status': status,
      'expirationDate': expirationDate,
      'location': location,
      'unitId': unitId,
      'isDeleted': isDeleted,
      'createAt': createAt?.toIso8601String(),
      'updateAt': updateAt?.toIso8601String(),
    };
  }

  BundleLine copyWith({
    String? id,
    String? transNo,
    String? productCode,
    String? productName,
    String? bin,
    String? lotNo,
    double? demandQty,
    double? actualQty,
    int? status,
    String? expirationDate,
    String? location,
    int? unitId,
    bool? isDeleted,
    DateTime? createAt,
    DateTime? updateAt,
  }) {
    return BundleLine(
      id: id ?? this.id,
      transNo: transNo ?? this.transNo,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      bin: bin ?? this.bin,
      lotNo: lotNo ?? this.lotNo,
      demandQty: demandQty ?? this.demandQty,
      actualQty: actualQty ?? this.actualQty,
      status: status ?? this.status,
      expirationDate: expirationDate ?? this.expirationDate,
      location: location ?? this.location,
      unitId: unitId ?? this.unitId,
      isDeleted: isDeleted ?? this.isDeleted,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
    );
  }
}

