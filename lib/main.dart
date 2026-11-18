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
import 'package:got_report/core/router/app_router.dart';
import 'package:got_report/core/theme/app_theme.dart';
import 'package:got_report/core/theme/theme_cubit.dart';
import 'package:got_report/features/login/data/datasources/auth_remote_data_source.dart';
import 'package:got_report/features/login/data/repositories/auth_repository_impl.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';
import 'package:got_report/features/posts/data/datasources/posts_remote_data_source.dart';
import 'package:got_report/features/posts/data/repositories/posts_repository_impl.dart';
import 'package:got_report/features/posts/domain/repositories/posts_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts are bundled in assets/google_fonts; never download at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  await dotenv.load(fileName: '.env');
  final sharedPreferences = await SharedPreferences.getInstance();

  final tokenStorage = TokenStorage();
  final sessionCubit = SessionCubit(
    await tokenStorage.hasSession()
        ? SessionStatus.authenticated
        : SessionStatus.unauthenticated,
  );

  runApp(
    MyApp(
      sharedPreferences: sharedPreferences,
      tokenStorage: tokenStorage,
      sessionCubit: sessionCubit,
    ),
  );
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

  @override
  void dispose() {
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
          ),
        ),
        RepositoryProvider<PostsRemoteDataSource>(
          create: (context) =>
              PostsRemoteDataSourceImpl(context.read<ApiClient>()),
        ),
        RepositoryProvider<PostsRepository>(
          create: (context) =>
              PostsRepositoryImpl(context.read<PostsRemoteDataSource>()),
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
