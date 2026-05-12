import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/security/crypto_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/di/injection.dart';
import '../../../routes/route_names.dart';

/// Port từ screens/Login.js — phần handleScan
/// Quét QR → decrypt TripleDES → đăng nhập loginByQR
class QRLoginScreen extends StatefulWidget {
  const QRLoginScreen({super.key});

  @override
  State<QRLoginScreen> createState() => _QRLoginScreenState();
}

class _QRLoginScreenState extends State<QRLoginScreen> {
  final MobileScannerController _scanCtrl = MobileScannerController();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  // ─── Xử lý QR scan ───────────────────────────────────────────
  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() { _isProcessing = true; _errorMessage = null; });
    await _scanCtrl.stop();

    try {
      // Decrypt TripleDES giống Login.js → verifyMd5Hash(data)
      final decrypted = CryptoService.decryptQRCode(raw);
      if (decrypted.isEmpty) {
        _setError('QRコードの形式が正しくありません');
        return;
      }

      // Format: "username|password"
      final parts = decrypted.split('|');
      if (parts.length < 2) {
        _setError('QRコードの形式が正しくありません');
        return;
      }

      final username = parts[0].trim();
      final password = parts[1].trim();

      if (username.isEmpty || password.isEmpty) {
        _setError('ユーザーとパスワードを入力してください');
        return;
      }

      final repo = sl<AuthRepository>();
      final result = await repo.loginByQR(username, password);

      if (!mounted) return;

      if (result != null) {
        final user = UserInfo(
          username: username,
          token: result['token'] as String? ?? '',
          refreshToken: result['refreshToken'] as String? ?? '',
          loginType: 'QR',
        );
        final authBloc = context.read<AuthBloc>();
        authBloc.add(LoggedIn(user));
        await authBloc.stream.firstWhere((s) => s is AuthAuthenticated);
        if (!mounted) return;
        context.go(RouteNames.tenantSelection);
      } else {
        _setError('WMSサーバーに接続できません。\nネットワークを確認してください。');
      }
    } catch (_) {
      _setError('ログイン中にエラーが発生しました');
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() { _isProcessing = false; _errorMessage = msg; });
    _scanCtrl.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.themeBackground,
        foregroundColor: AppColors.white,
        title: const Text(
          'QRコードでログイン',
          style: TextStyle(fontFamily: 'MSPGothic', fontSize: 16),
        ),
      ),
      body: Stack(
        children: [
          // ── Scanner ─────────────────────────────────────────
          MobileScanner(
            controller: _scanCtrl,
            onDetect: _handleScan,
          ),

          // ── Viewfinder overlay ──────────────────────────────
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryLight, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // ── Loading / Error ─────────────────────────────────
          if (_isProcessing)
            Container(
              color: AppColors.shadowMedium,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryLight),
              ),
            ),

          // ── Error message ───────────────────────────────────
          if (_errorMessage != null)
            Positioned(
              bottom: 80,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.btnRed.withAlpha(230),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontFamily: 'MSPGothic',
                    color: AppColors.white,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // ── Hint ────────────────────────────────────────────
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'QRコードをカメラに向けてください',
              style: TextStyle(
                fontFamily: 'MSPGothic',
                color: AppColors.white.withAlpha(180),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
