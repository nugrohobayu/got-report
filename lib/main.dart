import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:got_report/core/network/api_client.dart';
import 'package:got_report/core/network/download_service.dart';
import 'package:got_report/core/router/app_router.dart';
import 'package:got_report/core/theme/app_theme.dart';
import 'package:got_report/core/theme/theme_cubit.dart';
import 'package:got_report/features/posts/data/datasources/posts_remote_data_source.dart';
import 'package:got_report/features/posts/data/repositories/posts_repository_impl.dart';
import 'package:got_report/features/posts/domain/repositories/posts_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(MyApp(sharedPreferences: sharedPreferences));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const MyApp({super.key, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>(create: (_) => ApiClient()),
        RepositoryProvider<DownloadService>(
          create: (_) => DownloadService(),
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
      child: BlocProvider(
        create: (_) => ThemeCubit(sharedPreferences),
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: 'MyApp',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              routerConfig: AppRouter.router,
            );
          },
        ),
      ),
    );
  }
}
