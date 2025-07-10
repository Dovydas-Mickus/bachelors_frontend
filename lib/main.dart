
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/core/repositories/authentication_repository.dart';
import 'package:micki_nas/frontend/login_screen/cubit/login_cubit.dart';
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
  final UserCubit userCubit = UserCubit(api: api);
  final FilesCubit filesCubit = FilesCubit(api: api);
  final LoginCubit loginCubit = LoginCubit();

  runApp(
    MultiRepositoryProvider(

      providers: [
        RepositoryProvider(create: (_) => api),
        RepositoryProvider(create: (_) => AuthenticationRepository()),
    ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),

          BlocProvider.value(value: filesCubit),

          BlocProvider(
            create: (context) => AppCubit(
              api: api,
              filesCubit: filesCubit,
              userCubit: userCubit,
              loginCubit: loginCubit,
            ),
          ),
          BlocProvider(create: (_) => loginCubit),
          BlocProvider(
              create: (_) => userCubit
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