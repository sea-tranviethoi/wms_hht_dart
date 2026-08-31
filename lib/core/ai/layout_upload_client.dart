import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

/// Client for uploading a Location's warehouse floor-plan image to
/// [AppConstants.visionHost] (mock_vision_server.py) and polling for the
/// parse result.
///
/// Upload + parse is a two-step, poll-based flow rather than one long
/// request: the OCR/skeletonize (or local Ollama vision-model) parse can
/// take from a few seconds to a couple of minutes, and holding one HTTP
/// request open that whole time is fragile — routers/NAT/VPNs commonly
/// reset an idle-looking connection well before that. uploadLayout only
/// waits for the (fast) save-to-disk step; pollStatus is called repeatedly
/// afterwards to learn the real outcome. Same pattern as WebUIFinal's
/// VisionAiLayoutService.cs on the WMS side.
class LayoutUploadClient {
  late final Dio _dio;

  LayoutUploadClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.visionHost,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  /// Uploads [imageFile] for [locationCode]. Returns once the file is saved
  /// (fast) — parsing continues in the background on the server. Throws
  /// [LayoutUploadException] on failure.
  Future<void> uploadLayout(String locationCode, File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final b64 = base64Encode(bytes);
      final fileName = imageFile.path.split(Platform.pathSeparator).last;

      final res = await _dio.post('/api/layout/upload', data: {
        'locationCode': locationCode,
        'fileName': fileName,
        'image': b64,
      });
      final data = res.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw LayoutUploadException(data['error']?.toString() ?? 'アップロードに失敗しました');
      }
    } on DioException catch (e) {
      throw LayoutUploadException(_friendly(e));
    } on LayoutUploadException {
      rethrow;
    } catch (e) {
      throw LayoutUploadException(e.toString());
    }
  }

  /// Polls the parse job's status for [locationCode]. Returns "processing",
  /// "done", "error", or "none" (see mock_vision_server.py's
  /// /api/layout/status). Throws [LayoutUploadException] only on a
  /// transport-level failure, not on a "processing"/"error" status.
  Future<LayoutStatus> pollStatus(String locationCode) async {
    try {
      final res = await _dio.get('/api/layout/status',
          queryParameters: {'locationCode': locationCode});
      final data = res.data as Map<String, dynamic>;
      return LayoutStatus(
        status: (data['status'] ?? 'processing').toString(),
        spatialBins: (data['spatialBins'] as num?)?.toInt() ?? 0,
        specialBins: (data['specialBins'] as num?)?.toInt() ?? 0,
        error: data['error']?.toString(),
      );
    } on DioException catch (e) {
      // A single failed poll (transient network blip) isn't the job
      // failing — report "processing" so the caller just tries again.
      return LayoutStatus(status: 'processing', transientError: _friendly(e));
    }
  }

  String _friendly(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
        return 'Vision AI サーバーに接続できません';
      case DioExceptionType.receiveTimeout:
        return 'サーバーの応答がタイムアウトしました';
      default:
        final body = e.response?.data;
        if (body is Map && body['error'] != null) return body['error'].toString();
        return e.message ?? 'アップロードに失敗しました';
    }
  }
}

class LayoutStatus {
  /// "processing" | "done" | "error" | "none"
  final String status;
  final int spatialBins;
  final int specialBins;
  final String? error;
  final String? transientError;

  const LayoutStatus({
    required this.status,
    this.spatialBins = 0,
    this.specialBins = 0,
    this.error,
    this.transientError,
  });
}

class LayoutUploadException implements Exception {
  final String message;
  const LayoutUploadException(this.message);
  @override
  String toString() => message;
}
