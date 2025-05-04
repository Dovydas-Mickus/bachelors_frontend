import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/home_screen/src/files/cubit/files_cubit.dart';

import '../../core/repositories/API.dart';
import '../home_screen/home_screen.dart';
import '../login_screen/login_screen.dart';
import 'cubit/app_cubit.dart';




class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(builder: (context, state) {
        AppStatus appStatus = context.read<AppCubit>().state.appStatus;
        if(appStatus == AppStatus.loading) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (appStatus == AppStatus.loggedOut) {
          return LoginScreen();
        }
        if (appStatus == AppStatus.loggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await context.read<APIRepository>().fetchCloud();
            if (context.mounted) {
              await context.read<FilesCubit>().loadFolder('');
            }
          });
          return HomeScreen();
        }
        return Text('Something went wrong');
      }
    );
  }
}