import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/login_screen/login_screen.dart';

import '../home_screen/home_screen.dart';
import 'cubit/app_cubit.dart';


class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        switch (state.appStatus) {
          case AppStatus.loading:
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          case AppStatus.loggedOut:
            return const LoginScreen();
          case AppStatus.loggedIn:
            return const HomeScreen();
        }
      },
    );
  }
}