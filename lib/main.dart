
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import 'core/repositories/API.dart';
import 'frontend/home_screen/src/files/cubit/files_cubit.dart';
import 'frontend/login_screen/login_screen.dart';
import 'frontend/main_screen/cubit/app_cubit.dart';
import 'frontend/main_screen/main_screen.dart';
import 'frontend/main_screen/theme_data/cubit/theme_cubit.dart';
import 'frontend/main_screen/theme_data/theme_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  APIRepository api = APIRepository();
  runApp(
    RepositoryProvider(
      create: (context) => api,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (context) => FilesCubit(api: context.read<APIRepository>())..loadFolder('')),
          BlocProvider(
            create: (context) => AppCubit(
              api: api,
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            return MaterialApp(
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: state.themeMode,
              routes: {
                '/login': (context) => LoginScreen(),
              },
              home: MainScreen(),
            );
          },
        ),
      ),
    ),
  );
}
