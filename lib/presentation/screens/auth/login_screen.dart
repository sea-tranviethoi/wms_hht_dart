import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/di/injection.dart';
import '../../../routes/route_names.dart';

/// Ported from screens/Login.js
/// Login with username/password + button to switch to QR login
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ─── Login handler ────────────────────────────────────────────
  Future<void> _handleLogin() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'ユーザー名とパスワードを入力してください');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    FocusScope.of(context).unfocus();

    try {
      final repo = sl<AuthRepository>();
      final result = await repo.login(username, password);

      if (!mounted) return;

      if (result != null) {
        final user = UserInfo(
          username: username,
          token: result['token'] as String? ?? '',
          refreshToken: result['refreshToken'] as String? ?? '',
          loginType: 'NORMAL',
        );
        final authBloc = context.read<AuthBloc>();
        authBloc.add(LoggedIn(user));
        // Wait for the bloc to process the event → state becomes AuthAuthenticated
        // before navigating, to prevent the router redirect sending back to login.
        await authBloc.stream.firstWhere((s) => s is AuthAuthenticated);
        if (!mounted) return;
        context.go(RouteNames.tenantSelection);
      } else {
        setState(() => _errorMessage =
            'ユーザー名またはパスワードが正しくありません。\n入力内容を確認し再度ログインしてください。');
      }
    } catch (e) {
      setState(() => _errorMessage =
          'WMSサーバーに接続できません。\nネットワークを確認してください。');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.themeBackground,
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // ── Header ──────────────────────────────────────
              const SizedBox(height: 24),
              Text(
                'FBTHHT',
                style: TextStyle(
                  fontFamily: AppStyles.font,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '倉庫管理システム',
                style: TextStyle(
                  fontFamily: AppStyles.font,
                  fontSize: 14,
                  color: AppColors.lighter,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // ── Card form ───────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Username
                    _buildLabel('ユーザー名'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _usernameCtrl,
                      focusNode: _usernameFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                      style: const TextStyle(fontFamily: AppStyles.font),
                      decoration: _inputDecoration('ユーザー名を入力', Icons.person_outline),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    _buildLabel('パスワード'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      style: const TextStyle(fontFamily: AppStyles.font),
                      decoration: _inputDecoration(
                        'パスワードを入力',
                        Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.gray,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontFamily: AppStyles.font,
                          color: AppColors.textError,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Login button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'ログイン',
                                style: TextStyle(
                                  fontFamily: AppStyles.font,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // QR Login button
                    OutlinedButton.icon(
                      onPressed: () => context.push(RouteNames.qrLogin),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text(
                        'QRコードでログイン',
                        style: TextStyle(fontFamily: AppStyles.font),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.themeBackground,
                        side: const BorderSide(color: AppColors.themeBackground),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Version info
              const SizedBox(height: 24),
              Text(
                'V1.10.2 — Development',
                style: TextStyle(
                  fontFamily: AppStyles.font,
                  color: AppColors.lighter,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: AppStyles.font,
          fontSize: 13,
          color: AppColors.blackTextColor,
          fontWeight: FontWeight.w600,
        ),
      );

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: AppStyles.font,
          color: AppColors.textPlaceholder,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: AppColors.gray, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.ghostWhiteColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.themeBackground, width: 1.5),
        ),
      );
}
