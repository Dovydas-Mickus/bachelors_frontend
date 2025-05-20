// --- In main.dart ---

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/user_cubit/user_cubit.dart';

import 'core/repositories/API.dart';
import 'frontend/home_screen/src/files/cubit/files_cubit.dart';
import 'frontend/login_screen/login_screen.dart';
import 'frontend/main_screen/cubit/app_cubit.dart';
import 'frontend/main_screen/main_screen.dart';
import 'frontend/main_screen/theme_data/cubit/theme_cubit.dart';
import 'frontend/main_screen/theme_data/theme_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final APIRepository api = await APIRepository.create();

  final FilesCubit filesCubit = FilesCubit(api: api);

  runApp(
    RepositoryProvider.value(
      value: api,
      child: MultiBlocProvider(
        providers: [
          // Standard Bloc creation
          BlocProvider(create: (_) => ThemeCubit()),

          BlocProvider.value(value: filesCubit),

          BlocProvider(
            create: (context) => AppCubit(
              api: api,
              filesCubit: filesCubit,
            ),
          ),

          BlocProvider(
              create: (_) => UserCubit(api: api)
            ..loadUserProfile(),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              title: 'Micki NAS',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeState.themeMode,
              routes: {
                '/login': (context) => const LoginScreen(),
              },
              home: const MainScreen(),
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    ),
  );
}