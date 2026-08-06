import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'routes/route_names.dart';

import 'core/di/injection.dart';
import 'core/network/network_info.dart';
import 'core/storage/secure_storage.dart';
import 'data/repositories/auth_repository.dart';
import 'data/datasources/remote/picking_remote_datasource.dart';
import 'data/repositories/master_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/master/master_bloc.dart';
import 'presentation/blocs/picking/picking_bloc.dart';
import 'presentation/blocs/update/update_cubit.dart';
import 'presentation/widgets/update_dialog.dart';
import 'routes/app_router.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      debugPrint('🔴 Flutter error: ${details.exception}');
      debugPrint(details.stack.toString());
    };

    // Lock orientation to portrait for HHT devices
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Initialize all dependencies via get_it
    await initDependencies();

    runApp(const FbtHhtApp());
  }, (error, stack) {
    debugPrint('🔴 Uncaught error: $error');
    debugPrint(stack.toString());
  });
}

/// Shows the update dialog, but only once we've navigated away from the
/// splash screen. If the update check finishes while splash is still up
/// (e.g. before auth resolves), showing the dialog now would be torn down
/// by the splash → destination navigation. So we retry each frame until the
/// current route is no longer the splash.
void _showUpdateWhenOffSplash([int attempt = 0]) {
  if (attempt == 0) {
    // ignore: avoid_print
    print('🟢 [Update] listener fired → trying to show dialog');
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Use the root navigator's context (below the router) — it can both
    // read the UpdateCubit and provide a Navigator for showDialog.
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) {
      if (attempt < 180) _showUpdateWhenOffSplash(attempt + 1);
      return;
    }

    final location =
        appRouter.routerDelegate.currentConfiguration.uri.path;

    if (location == RouteNames.splash) {
      // Still on splash — give up after ~3s to avoid an endless loop.
      if (attempt < 180) {
        _showUpdateWhenOffSplash(attempt + 1);
      } else {
        // ignore: avoid_print
        print('🔴 [Update] gave up — still on splash after 180 frames');
      }
      return;
    }

    // ignore: avoid_print
    print('🟢 [Update] showing dialog (route=$location)');
    UpdateDialog.show(navContext);
  });
}

class FbtHhtApp extends StatelessWidget {
  const FbtHhtApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── ScreenUtil: design baseline = 360×800 (Keyence BT-A series)
    // minTextAdapt: false → text scales by screen WIDTH (not shrunk by
    // the small height on a 3.5" 320×480 HHT display).
    // splitScreenMode: false → HHT does not support split-screen.
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: false,
      splitScreenMode: false,
      builder: (_, __) => MultiBlocProvider(
        providers: [
          BlocProvider<UpdateCubit>(
            create: (_) => sl<UpdateCubit>(),
          ),
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
          // Phase 4-8: add per-module BLoCs here
        ],
        child: MaterialApp.router(
          title: 'FBTHHT',
          debugShowCheckedModeBanner: false,

          // ── Clamp system text-scale (accessibility) ────────
          // Prevent the user/OS from enlarging text so much that it breaks the layout.
          // Range [0.85 – 1.2] is appropriate for 3.5"–6" HHT screens.
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: mq.textScaler.clamp(
                  minScaleFactor: 0.85,
                  maxScaleFactor: 1.20,
                ),
              ),
              child: BlocListener<UpdateCubit, UpdateState>(
                listenWhen: (_, curr) => curr is UpdateAvailable,
                listener: (context, _) => _showUpdateWhenOffSplash(),
                child: child!,
              ),
            );
          },

          // ── Theme ──────────────────────────────────────────
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'MSPGothic',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3D6E96),
            ),
            appBarTheme: const AppBarTheme(
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              titleTextStyle: TextStyle(
                fontFamily: 'MSPGothic',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              iconTheme: IconThemeData(color: Colors.white, size: 32),
            ),
            cardTheme: const CardThemeData(
              color: Color(0xFFF3F3F3),
              surfaceTintColor: Colors.transparent,
              elevation: 1,
              shadowColor: Color(0x1A000000),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFFFFFFFF),
              surfaceTintColor: Colors.transparent,
            ),
          ),

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
