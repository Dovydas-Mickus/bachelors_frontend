// --- In main.dart ---

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/user_cubit/user_cubit.dart'; // Assuming correct path

import 'core/repositories/API.dart'; // Assuming correct path
import 'frontend/home_screen/src/files/cubit/files_cubit.dart'; // Assuming correct path
import 'frontend/login_screen/login_screen.dart'; // Assuming correct path
import 'frontend/main_screen/cubit/app_cubit.dart'; // Assuming correct path
import 'frontend/main_screen/main_screen.dart'; // Assuming correct path
import 'frontend/main_screen/theme_data/cubit/theme_cubit.dart'; // Assuming correct path
import 'frontend/main_screen/theme_data/theme_data.dart'; // Assuming correct path

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Create and initialize Repository FIRST
  final APIRepository api = await APIRepository.create();

  // 2. Create the SINGLE FilesCubit instance
  final FilesCubit filesCubit = FilesCubit(api: api);
  // REMOVE initial load here - AppCubit's _initState will trigger it
  // filesCubit.loadFolder('');

  // 3. Run the App
  runApp(
    // Provide the Repository
    RepositoryProvider.value(
      value: api,
      child: MultiBlocProvider(
        providers: [
          // Standard Bloc creation
          BlocProvider(create: (_) => ThemeCubit()),

          // --- FIX: Provide the EXISTING filesCubit instance using .value ---
          BlocProvider.value(value: filesCubit),
          // --- End Fix ---

          // Create AppCubit, injecting the existing api and filesCubit
          BlocProvider(
            create: (context) => AppCubit(
              api: api,
              filesCubit: filesCubit,
              // AppCubit's constructor now calls _initState automatically
            ),
          ),

          // Create UserCubit, injecting api
          BlocProvider(
              create: (_) => UserCubit(api: api)
            // Decide when to load profile - often after login confirmation in AppCubit
            ..loadUserProfile(), // Maybe trigger this from AppCubit instead?
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) { // Renamed 'state' to avoid conflict
            return MaterialApp(
              title: 'Micki NAS',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeState.themeMode, // Use renamed variable
              routes: {
                // Use const constructors where possible
                '/login': (context) => const LoginScreen(),
              },
              // MainScreen will react to AppCubit's state
              home: const MainScreen(), // Use const
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    ),
  );
}