import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/theme_config.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_button.dart';
import '../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../core/utils/connectivity_check.dart';
import '../../core/utils/encryption.dart';
import '../../l10n/app_strings.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  MobileScannerController? _scannerController;
  bool _isScanning = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final strings = AppStrings.ofWithoutWatch(context);
    final isConnected = await ConnectivityCheck.isConnected();
    if (!isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.loginNoInternet),
            backgroundColor: AppColors.textError,
          ),
        );
      }
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        if (success) {
          context.go(RouteNames.mainMenu);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.loginWrongCredential),
              backgroundColor: AppColors.textError,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String message = strings.loginFailed;
        if (e.toString().contains('WMSサーバに接続できません')) {
          message = strings.loginServerIssue;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.textError,
          ),
        );
      }
    }
  }

  Future<void> _handleQRScan(String scannedData) async {
    try {
      // Decrypt QR data
      final decryptedData = verifyMd5Hash(scannedData);
      final parts = decryptedData.split('|');
      
      final strings = AppStrings.ofWithoutWatch(context);
      if (parts.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.qrInvalid),
              backgroundColor: AppColors.textError,
            ),
          );
        }
        return;
      }

      final userName = parts[0];
      final password = parts[1];

      if (userName.isEmpty || password.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.qrInvalid),
              backgroundColor: AppColors.textError,
            ),
          );
        }
        return;
      }

      final isConnected = await ConnectivityCheck.isConnected();
      if (!isConnected) {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.loginNoInternet),
            backgroundColor: AppColors.textError,
          ),
        );
        }
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.loginByQR(userName, password);

      if (mounted) {
        if (success) {
          context.go(RouteNames.mainMenu);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.loginWrongCredential),
              backgroundColor: AppColors.textError,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final strings = AppStrings.ofWithoutWatch(context);
        String message = strings.loginFailed;
        if (e.toString().contains('WMSサーバに接続できません')) {
          message = strings.loginServerIssue;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.textError,
          ),
        );
      }
    }
  }

  void _startQRScanner() {
    setState(() {
      _isScanning = true;
      _scannerController = MobileScannerController();
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: 400,
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _scannerController?.stop();
                      Navigator.pop(context);
                      _handleQRScan(barcode.rawValue!);
                      setState(() {
                        _isScanning = false;
                      });
                      break;
                    }
                  }
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    _scannerController?.stop();
                    Navigator.pop(context);
                    setState(() {
                      _isScanning = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: authProvider.isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo_1.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        // Logo
                        Image.asset(
                          'assets/images/logo_1.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 40),
                        Builder(
                          builder: (context) {
                            final strings = AppStrings.of(context);
                            return Column(
                              children: [
                                CustomInput(
                                  label: strings.userName,
                                  controller: _usernameController,
                                  validator: (value) {
                                    if (value == null || value.length < 4) {
                                      return 'Username must be 4 characters long';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomInput(
                                  label: strings.password,
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  validator: (value) {
                                    if (value == null || value.length < 3) {
                                      return 'Password must be 8 characters long';
                                    }
                                    return null;
                                  },
                                  onSubmitted: (_) => _handleLogin(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 32),
                                CustomButton(
                                  text: strings.loginButton,
                                  type: ButtonType.success,
                                  isFullWidth: true,
                                  onPressed: _handleLogin,
                                  isLoading: authProvider.isLoading,
                                ),
                                const SizedBox(height: 16),
                                CustomButton(
                                  text: strings.qrLogin,
                                  type: ButtonType.outline,
                                  isFullWidth: true,
                                  icon: Icons.qr_code_scanner,
                                  onPressed: _startQRScanner,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  strings.loginHint,
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        // Version
                        Text(
                          '${AppConfig.env} V${AppConfig.version}',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
