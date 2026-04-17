import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../models/warehouse_receipt/receipt_line.dart';
import '../../models/warehouse_receipt/receipt_order.dart';
import '../../models/warehouse_receipt/receipt_staging.dart';

class WRRemoteDataSource {
  final DioClient _dioClient;

  WRRemoteDataSource(DioClient dioClient) : _dioClient = dioClient;

  // ─── Orders ───────────────────────────────────────────────────

  Future<List<ReceiptOrder>> getOrders() async {
    final resp = await _dioClient.dio.get(ApiEndpoints.warehouseReceiptOrder);
    return _parseList(resp.data, ReceiptOrder.fromJson);
  }

  Future<List<ReceiptOrder>> getOrdersByReceiptNo(String receiptNo) async {
    final url = ApiEndpoints.warehouseReceiptOrderByReceiptNo
        .replaceAll('{receiptNo}', receiptNo);
    final resp = await _dioClient.dio.get(url);
    return _parseList(resp.data, ReceiptOrder.fromJson);
  }

  // ─── Lines ────────────────────────────────────────────────────

  Future<List<ReceiptLine>> getLines() async {
    final resp =
        await _dioClient.dio.get(ApiEndpoints.warehouseReceiptOrderLine);
    return _parseList(resp.data, ReceiptLine.fromJson);
  }

  Future<List<ReceiptLine>> getLinesByReceiptNo(String receiptNo) async {
    final url = ApiEndpoints.warehouseReceiptOrderLineByReceiptNo
        .replaceAll('{receiptNo}', receiptNo);
    final resp = await _dioClient.dio.get(url);
    return _parseList(resp.data, ReceiptLine.fromJson);
  }

  Future<bool> updateLine(ReceiptLine line) async {
    final resp = await _dioClient.dio.post(
      ApiEndpoints.warehouseReceiptOrderLineUpdate,
      data: line.toJson(),
    );
    return resp.statusCode == 200;
  }

  // ─── Staging ──────────────────────────────────────────────────

  Future<List<ReceiptStaging>> getStagingByReceiptNo(String receiptNo) async {
    final url = ApiEndpoints.warehouseReceiptStagingByReceiptNo
        .replaceAll('{receiptNo}', receiptNo);
    final resp = await _dioClient.dio.get(url);
    return _parseList(resp.data, ReceiptStaging.fromJson);
  }

  Future<bool> addStagingRange(List<ReceiptStaging> stagingList) async {
    final resp = await _dioClient.dio.post(
      ApiEndpoints.warehouseReceiptStagingAddRange,
      data: stagingList.map((s) => s.toJson()).toList(),
    );
    final data = resp.data;
    if (data is Map) return data['succeeded'] == true;
    return resp.statusCode == 200;
  }

  Future<bool> deleteStaging(ReceiptStaging staging) async {
    final resp = await _dioClient.dio.post(
      ApiEndpoints.warehouseReceiptStagingDelete,
      data: staging.toJson(),
    );
    return resp.statusCode == 200;
  }

  // ─── Complete ─────────────────────────────────────────────────

  Future<bool> completeReceipt() async {
    final resp =
        await _dioClient.dio.post(ApiEndpoints.completeWarehouseReceipt);
    return resp.statusCode == 200;
  }

  // ─── HHT Status ───────────────────────────────────────────────

  Future<bool> updateHHTStatus({
    required int status,
    required int receiptId,
    required int flag,
    String? hhtInfo,
  }) async {
    final body = <String, dynamic>{
      'status': status,
      'receiptId': receiptId,
      'flag': flag,
    };
    if (hhtInfo != null) body['hhtInfo'] = hhtInfo;

    final resp = await _dioClient.dio.post(
      ApiEndpoints.updateHHTStatus,
      data: body,
    );
    return resp.statusCode == 200;
  }

  // ─── Helpers ──────────────────────────────────────────────────

  List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    List<dynamic> dataList = [];
    if (raw is List) {
      dataList = raw;
    } else if (raw is Map && raw['data'] != null) {
      dataList = raw['data'] as List<dynamic>;
    }
    return dataList.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}
