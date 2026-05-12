import '../../../core/utils/json_utils.dart';

import 'receipt_line.dart';

/// Model for staging data (offline scanned data)
class ReceiptStaging {
  final int? id;
  final String receiptNo;
  final String productCode;
  final int? unitId;
  final double orderQty;
  final double transQty;
  final String? bin;
  final String? lotNo;
  final String? expirationDate;
  final int? receiptLineId;
  final int status;
  final String? janCode;
  final DateTime? createAt;
  final DateTime? updateAt;

  ReceiptStaging({
    this.id,
    required this.receiptNo,
    required this.productCode,
    this.unitId,
    required this.orderQty,
    required this.transQty,
    this.bin,
    this.lotNo,
    this.expirationDate,
    this.receiptLineId,
    this.status = 1,
    this.janCode,
    this.createAt,
    this.updateAt,
  });

  factory ReceiptStaging.fromJson(Map<String, dynamic> json) {
    return ReceiptStaging(
      id: toInt(json['id']),
      receiptNo: (json['receiptNo'] ?? '').toString(),
      productCode: (json['productCode'] ?? '').toString(),
      unitId: toInt(json['unitId']),
      orderQty: toDouble(json['orderQty']) ?? 0,
      transQty: toDouble(json['transQty']) ?? 0,
      bin: json['bin']?.toString(),
      lotNo: json['lotNo']?.toString(),
      expirationDate: json['expirationDate']?.toString(),
      receiptLineId: toInt(json['receiptLineId']),
      status: toInt(json['status']) ?? 1,
      janCode: json['janCode']?.toString(),
      createAt: toDate(json['createAt']),
      updateAt: toDate(json['updateAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiptNo': receiptNo,
        'productCode': productCode,
        'unitId': unitId,
        'orderQty': orderQty,
        'transQty': transQty,
        'bin': bin,
        'lotNo': lotNo,
        'expirationDate': expirationDate,
        'receiptLineId': receiptLineId,
        'status': status,
        'janCode': janCode,
        'createAt': createAt?.toIso8601String(),
        'updateAt': updateAt?.toIso8601String(),
      };
}

/// Model for product error images
class ProductErrorImage {
  final int receiptLineId;
  final int statusError;
  final List<ErrorImageData> errorImages;

  ProductErrorImage({
    required this.receiptLineId,
    required this.statusError,
    required this.errorImages,
  });

  factory ProductErrorImage.fromJson(Map<String, dynamic> json) {
    return ProductErrorImage(
      receiptLineId: toInt(json['receiptLineId']) ?? 0,
      statusError: toInt(json['statusError']) ?? 0,
      errorImages: (json['errorImages'] as List?)
              ?.map((e) => ErrorImageData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'receiptLineId': receiptLineId,
        'statusError': statusError,
        'errorImages': errorImages.map((e) => e.toJson()).toList(),
      };
}

class ErrorImageData {
  final String filePath;
  final String fileName;
  final String imageBase64;

  ErrorImageData({
    required this.filePath,
    required this.fileName,
    required this.imageBase64,
  });

  factory ErrorImageData.fromJson(Map<String, dynamic> json) {
    return ErrorImageData(
      filePath: (json['filePath'] ?? '').toString(),
      fileName: (json['fileName'] ?? '').toString(),
      imageBase64: (json['imageBase64'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'fileName': fileName,
        'imageBase64': imageBase64,
      };
}

/// Model for offline scanned receipt (stored locally)
class OfflineReceiptData {
  final String warehouseReceiptNo;
  final int tenantId;
  final List<ScannedReceiptLine> warehouseReceiptLinesScanned;
  final List<ReceiptLine> warehouseReceiptLines;
  final List<ImageData>? dataImage;

  OfflineReceiptData({
    required this.warehouseReceiptNo,
    required this.tenantId,
    required this.warehouseReceiptLinesScanned,
    required this.warehouseReceiptLines,
    this.dataImage,
  });

  factory OfflineReceiptData.fromJson(Map<String, dynamic> json) {
    return OfflineReceiptData(
      warehouseReceiptNo: (json['WarehouseReceiptNo'] ?? '').toString(),
      tenantId: toInt(json['TenantId']) ?? 0,
      warehouseReceiptLinesScanned:
          (json['WarehouseReceiptLinesScanned'] as List?)
                  ?.map((e) =>
                      ScannedReceiptLine.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
      warehouseReceiptLines: (json['WarehouseReceiptLines'] as List?)
              ?.map((e) => ReceiptLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dataImage: (json['dataImage'] as List?)
          ?.map((e) => ImageData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'WarehouseReceiptNo': warehouseReceiptNo,
        'TenantId': tenantId,
        'WarehouseReceiptLinesScanned':
            warehouseReceiptLinesScanned.map((e) => e.toJson()).toList(),
        'WarehouseReceiptLines':
            warehouseReceiptLines.map((e) => e.toJson()).toList(),
        'dataImage': dataImage?.map((e) => e.toJson()).toList(),
      };
}

class ScannedReceiptLine {
  final String warehouseReceiptNo;
  final String productCode;
  final int? unit;
  final double orderQty;
  final double actualQty;
  final String? bin;
  final String? lotNo;
  final String? expirationDate;
  final int? id;
  final int status;
  final String? janCode;

  ScannedReceiptLine({
    required this.warehouseReceiptNo,
    required this.productCode,
    this.unit,
    required this.orderQty,
    required this.actualQty,
    this.bin,
    this.lotNo,
    this.expirationDate,
    this.id,
    this.status = 1,
    this.janCode,
  });

  factory ScannedReceiptLine.fromJson(Map<String, dynamic> json) {
    return ScannedReceiptLine(
      warehouseReceiptNo: (json['WarehouseReceiptNo'] ?? '').toString(),
      productCode: (json['ProductCode'] ?? '').toString(),
      unit: toInt(json['Unit']),
      orderQty: toDouble(json['OrderQty']) ?? 0,
      actualQty: toDouble(json['ActualQty']) ?? 0,
      bin: json['Bin']?.toString(),
      lotNo: json['LotNo']?.toString(),
      expirationDate: json['ExpirationDate']?.toString(),
      id: toInt(json['id']),
      status: toInt(json['Status']) ?? 1,
      janCode: json['janCode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'WarehouseReceiptNo': warehouseReceiptNo,
        'ProductCode': productCode,
        'Unit': unit,
        'OrderQty': orderQty,
        'ActualQty': actualQty,
        'Bin': bin,
        'LotNo': lotNo,
        'ExpirationDate': expirationDate,
        'id': id,
        'Status': status,
        'janCode': janCode,
      };
}

class ImageData {
  final String base64;
  final String? uri;

  ImageData({
    required this.base64,
    this.uri,
  });

  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      base64: (json['base64'] ?? '').toString(),
      uri: json['uri']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'base64': base64,
        'uri': uri,
      };
}



