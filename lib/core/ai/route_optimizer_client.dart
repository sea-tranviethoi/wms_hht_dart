import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

/// Client for the picking route optimizer (proposal #7, "Nhóm A").
///
/// Sends the bin codes needed for a picking task to [AppConstants.visionHost]
/// (same server as [VisionClient] — see mock_vision_server.py's
/// /api/route/optimize endpoint). Each rack is a dead-end aisle, so the
/// server reduces the problem to a small TSP over the racks that contain a
/// needed bin (solved with Google OR-Tools) instead of every individual bin,
/// and returns the bin codes reordered for the shortest round trip (the
/// entrance is both the start and end point — see warehouse_layout.json).
class RouteOptimizerClient {
  late final Dio _dio;

  RouteOptimizerClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.visionHost,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  /// Returns [bins] reordered for the shortest round trip starting and
  /// ending at the warehouse entrance, using [locationCode]'s uploaded floor
  /// plan (each Location has its own layout on the server now -- see
  /// mock_vision_server.py's per-location /api/layout/upload). Throws
  /// [RouteOptimizerException] on failure, including when [locationCode] has
  /// no layout uploaded yet.
  Future<List<String>> optimize(String locationCode, List<String> bins) async {
    try {
      final res = await _dio.post('/api/route/optimize',
          data: {'locationCode': locationCode, 'bins': bins});
      final data = res.data as Map<String, dynamic>;
      final order = data['order'] as List;
      return order.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw RouteOptimizerException(_friendly(e));
    } catch (e) {
      throw RouteOptimizerException(e.toString());
    }
  }

  String _friendly(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
        return 'Route サーバーに接続できません';
      case DioExceptionType.receiveTimeout:
        return 'ルート計算がタイムアウトしました';
      default:
        final body = e.response?.data;
        if (body is Map && body['error'] != null) return body['error'].toString();
        return e.message ?? 'ルート計算に失敗しました';
    }
  }
}

class RouteOptimizerException implements Exception {
  final String message;
  const RouteOptimizerException(this.message);
  @override
  String toString() => message;
}
