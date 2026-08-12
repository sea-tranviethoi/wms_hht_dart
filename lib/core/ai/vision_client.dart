import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

/// Client for the cycle-count Vision AI server.
///
/// Sends a shelf photo plus the candidate item codes to [AppConstants.visionHost]
/// and returns which codes the model recognised in the image. Uses its own Dio
/// instance, separate from the main WMS API client (same pattern as AppUpdater).
class VisionClient {
  late final Dio _dio;

  VisionClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.visionHost,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 90), // VLM inference can be slow
      headers: {'Content-Type': 'application/json'},
    ));
  }

  /// Sends [imageFile] (a JPEG) and [candidateCodes], returns the recognised
  /// item codes. Throws [VisionException] on failure.
  Future<VisionResult> identify(
    File imageFile,
    List<String> candidateCodes,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final b64 = base64Encode(bytes);

      final res = await _dio.post('/api/vision/identify', data: {
        'image': b64,
        'itemCodes': candidateCodes,
      });

      final data = res.data as Map<String, dynamic>;
      final identified = (data['identified'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [];
      return VisionResult(
        identified: identified,
        isMock: data['mock'] == true,
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
        return '画像認識がタイムアウトしました';
      default:
        return e.message ?? '画像認識に失敗しました';
    }
  }
}

/// Result of a vision identify call.
class VisionResult {
  /// Item codes the model recognised in the image.
  final List<String> identified;

  /// True when the server returned a canned response (VLM not reachable).
  final bool isMock;

  const VisionResult({required this.identified, required this.isMock});
}

class VisionException implements Exception {
  final String message;
  const VisionException(this.message);
  @override
  String toString() => message;
}
