import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/di/injection.dart';
import 'core/network/network_info.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/datasources/remote/picking_remote_datasource.dart';
import 'data/repositories/master_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/master/master_bloc.dart';
import 'presentation/blocs/picking/picking_bloc.dart';
import 'routes/app_router.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      debugPrint('🔴 Flutter error: ${details.exception}');
      debugPrint(details.stack.toString());
    };

    // Khóa màn hình dọc cho thiết bị HHT
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Khởi tạo tất cả dependencies qua get_it
    await initDependencies();

    runApp(const FbtHhtApp());
  }, (error, stack) {
    debugPrint('🔴 Uncaught error: $error');
    debugPrint(stack.toString());
  });
}

class FbtHhtApp extends StatelessWidget {
  const FbtHhtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, __) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(
              authRepository: sl<AuthRepository>(),
              secureStorage:  sl<SecureStorage>(),
              networkInfo:    sl<NetworkInfo>(),
            )..add(AppStarted()),
          ),
          BlocProvider<MasterBloc>(
            create: (_) => MasterBloc(repository: sl<MasterRepository>()),
          ),
          BlocProvider<PickingBloc>(
            create: (_) => PickingBloc(remote: sl<PickingRemoteDataSource>()),
          ),
          // Phase 4-8: thêm BLoC của từng module ở đây
        ],
        child: MaterialApp.router(
          title: 'FBTHHT',
          debugShowCheckedModeBanner: false,

          // ── Theme (Material 3 + design tokens) ─────────────
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,

          // ── i18n (Japanese first) ──────────────────────────
          locale: const Locale('ja'),
          supportedLocales: const [Locale('ja'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // ── Router ─────────────────────────────────────────
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
