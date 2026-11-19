import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:got_report/core/auth/auth_interceptor.dart';
import 'package:got_report/core/auth/session_cubit.dart';
import 'package:got_report/core/auth/token_storage.dart';
import 'package:got_report/core/network/api_client.dart';
import 'package:got_report/core/network/download_service.dart';
import 'package:got_report/core/push/push_notifications.dart';
import 'package:got_report/core/push/push_service.dart';
import 'package:got_report/core/utils/app_logger.dart';
import 'package:got_report/core/router/app_router.dart';
import 'package:got_report/core/theme/app_theme.dart';
import 'package:got_report/core/theme/theme_cubit.dart';
import 'package:got_report/features/login/data/datasources/auth_remote_data_source.dart';
import 'package:got_report/features/login/data/repositories/auth_repository_impl.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';
import 'package:got_report/features/profil/data/datasources/profile_remote_data_source.dart';
import 'package:got_report/features/profil/data/repositories/profile_repository_impl.dart';
import 'package:got_report/features/profil/domain/repositories/profile_repository.dart';
import 'package:got_report/features/tugas_hari_ini/data/datasources/task_remote_data_source.dart';
import 'package:got_report/features/tugas_hari_ini/data/repositories/task_repository_impl.dart';
import 'package:got_report/features/tugas_hari_ini/domain/repositories/task_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts are bundled in assets/google_fonts; never download at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('id_ID');
  await _initFirebase();
  final sharedPreferences = await SharedPreferences.getInstance();

  final tokenStorage = TokenStorage();
  final sessionCubit = SessionCubit(
    !await tokenStorage.hasSession()
        ? SessionStatus.unauthenticated
        : await tokenStorage.readMustChangePassword()
            ? SessionStatus.passwordChangeRequired
            : SessionStatus.authenticated,
  );

  runApp(
    MyApp(
      sharedPreferences: sharedPreferences,
      tokenStorage: tokenStorage,
      sessionCubit: sessionCubit,
    ),
  );
}

/// Android reads its config from `android/app/google-services.json`. Push is
/// optional, so a missing or broken config only disables it.
Future<void> _initFirebase() async {
  if (!Platform.isAndroid) return;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    AppLogger.api('Firebase init failed, push disabled: $e');
  }
}

class MyApp extends StatefulWidget {
  final SharedPreferences sharedPreferences;
  final TokenStorage tokenStorage;
  final SessionCubit sessionCubit;

  const MyApp({
    super.key,
    required this.sharedPreferences,
    required this.tokenStorage,
    required this.sessionCubit,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ApiClient _apiClient = ApiClient(
    authInterceptor: AuthInterceptor(
      tokenStorage: widget.tokenStorage,
      // Refresh token expired / revoked → back to login.
      onSessionExpired: widget.sessionCubit.setUnauthenticated,
    ),
  );
  late final GoRouter _router = AppRouter.create(widget.sessionCubit);
  late final PushService _push = PushService(_apiClient);
  late final StreamSubscription<SessionStatus> _sessionSub;

  @override
  void initState() {
    super.initState();
    // Register for push on app start while logged in, and after each login.
    if (widget.sessionCubit.isAuthenticated) _push.registerDevice();
    _sessionSub = widget.sessionCubit.stream
        .where((s) => s == SessionStatus.authenticated)
        .listen((_) => _push.registerDevice());
    PushNotifications.init(onOpened: _openPushRoute);
  }

  /// Push payload route is `/tasks/<id>`. There is no task detail screen
  /// yet, so open Beranda; the router still sends logged-out users to login.
  void _openPushRoute(String? route) {
    AppLogger.routing('Push opened: $route');
    _router.go('/');
  }

  @override
  void dispose() {
    _sessionSub.cancel();
    _router.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: _apiClient),
        RepositoryProvider<TokenStorage>.value(value: widget.tokenStorage),
        RepositoryProvider<DownloadService>(
          create: (_) => DownloadService(),
        ),
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            remoteDataSource: AuthRemoteDataSourceImpl(_apiClient),
            tokenStorage: widget.tokenStorage,
            deviceFid: _push.deviceFid,
          ),
        ),
        RepositoryProvider<TaskRepository>(
          create: (_) =>
              TaskRepositoryImpl(TaskRemoteDataSourceImpl(_apiClient)),
        ),
        RepositoryProvider<ProfileRepository>(
          create: (_) =>
              ProfileRepositoryImpl(ProfileRemoteDataSourceImpl(_apiClient)),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: widget.sessionCubit),
          BlocProvider(create: (_) => ThemeCubit(widget.sharedPreferences)),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: 'Got Report',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              routerConfig: _router,
            );
          },
        ),
      ),
    );
  }
}
