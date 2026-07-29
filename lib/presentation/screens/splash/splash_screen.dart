import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/update/update_cubit.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../routes/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  // Holds the resolved auth route until update check also finishes
  String? _pendingRoute;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _fadeAnim = Tween(begin: 0.4, end: 1.0).animate(_controller);

    // AuthBloc already fires AppStarted on creation (see main.dart).
    // Here we only kick off the update check in parallel.
    context.read<UpdateCubit>().checkForUpdate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeNavigate(BuildContext context) {
    if (_pendingRoute == null) return;
    final updateState = context.read<UpdateCubit>().state;
    if (updateState is UpdateChecking) return; // still checking — wait
    context.go(_pendingRoute!);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Auth resolves → store route, then navigate if update is also done
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              _pendingRoute = RouteNames.mainMenu;
            } else if (state is AuthUnauthenticated) {
              _pendingRoute = RouteNames.login;
            }
            _maybeNavigate(context);
          },
        ),
        // Update check finishes → navigate if auth already resolved
        BlocListener<UpdateCubit, UpdateState>(
          listenWhen: (prev, curr) =>
              prev is UpdateChecking && curr is! UpdateChecking,
          listener: (context, state) {
            _maybeNavigate(context);
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.primaryLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnim,
                child: Text(
                  'FBTHHT',
                  style: TextStyle(
                    fontFamily: AppStyles.font,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '倉庫管理システム',
                style: TextStyle(
                  fontFamily: AppStyles.font,
                  fontSize: AppStyles.sizeBodyText,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: AppColors.white,
                strokeWidth: 2,
              ),
              const SizedBox(height: 16),
              // Show message only while checking update
              BlocBuilder<UpdateCubit, UpdateState>(
                builder: (context, state) {
                  if (state is UpdateChecking) {
                    return Text(
                      'アップデートを確認中...',
                      style: TextStyle(
                        fontFamily: AppStyles.font,
                        fontSize: AppStyles.sizeSubText,
                        color: AppColors.lighter,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
