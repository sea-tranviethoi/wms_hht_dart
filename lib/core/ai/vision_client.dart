import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

/// Client for the multi-QR photo scanner used in cycle counting.
///
/// Sends one photo (of several items with QR codes stuck on them) plus the
/// set of valid item codes to [AppConstants.visionHost]. The server decodes
/// every QR code in the photo with pyzbar, matches each by prefix against the
/// valid codes, and returns per-item counts plus the photo with highlight
/// boxes drawn on the matched codes. Uses its own Dio instance, separate from
/// the main WMS API client (same pattern as AppUpdater).
class VisionClient {
  late final Dio _dio;

  VisionClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.visionHost,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  /// Sends [imageFile] (a JPEG) and [validCodes], returns the decode result.
  /// Throws [VisionException] on failure.
  Future<VisionResult> identify(
    File imageFile,
    Set<String> validCodes,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final b64 = base64Encode(bytes);

      final res = await _dio.post('/api/vision/identify', data: {
        'image': b64,
        'validCodes': validCodes.toList(),
      });

      final data = res.data as Map<String, dynamic>;
      final matchedRaw = data['matched'] as Map<String, dynamic>? ?? const {};
      final matched = matchedRaw.map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      );
      final annotatedB64 = data['annotatedImage'] as String? ?? '';

      return VisionResult(
        matched: matched,
        unmatchedCount: (data['unmatchedCount'] as num?)?.toInt() ?? 0,
        totalDetected: (data['totalDetected'] as num?)?.toInt() ?? 0,
        annotatedImage:
            annotatedB64.isEmpty ? null : base64Decode(annotatedB64),
      );
    } on DioException catch (e) {
      throw VisionException(_friendly(e));
    } catch (e) {
      throw VisionException(e.toString());
    }
  }

  String _friendly(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
        return 'Vision サーバーに接続できません';
      case DioExceptionType.receiveTimeout:
        return '画像解析がタイムアウトしました';
      default:
        return e.message ?? '画像解析に失敗しました';
    }
  }
}

/// Result of scanning a photo for QR codes.
class VisionResult {
  /// itemCode -> number of units found in the photo.
  final Map<String, int> matched;

  /// QR codes detected in the photo that didn't match any valid item code.
  final int unmatchedCount;

  /// Total QR codes detected in the photo (matched + unmatched).
  final int totalDetected;

  /// The photo with highlight boxes drawn on every detected QR code.
  final Uint8List? annotatedImage;

  const VisionResult({
    required this.matched,
    required this.unmatchedCount,
    required this.totalDetected,
    required this.annotatedImage,
  });

  bool get isEmpty => matched.isEmpty && unmatchedCount == 0;
}

class VisionException implements Exception {
  final String message;
  const VisionException(this.message);
  @override
  String toString() => message;
}
