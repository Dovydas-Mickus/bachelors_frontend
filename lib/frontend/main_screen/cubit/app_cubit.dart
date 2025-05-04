import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/API.dart';
import '../../home_screen/src/files/cubit/files_cubit.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {

  final APIRepository api;
  final FilesCubit filesCubit;
  AppCubit({required this.api, required this.filesCubit}) : super(AppState(
    appStatus: AppStatus.loading,
  )) {
   _initState();
  }



  Future<void> _initState() async {
    emit(state.copyWith(appStatus: AppStatus.loading));
    if (await api.refreshAccessToken()) {
      emit(state.copyWith(appStatus: AppStatus.loggedIn));
    } else {
      emit(state.copyWith(appStatus: AppStatus.loggedOut));
    }
  }

  Future<void> performLogout() async {
    emit(state.copyWith(appStatus: AppStatus.loading)); // Show loading indicator
    await api.logout(); // Await the API cleanup
    emit(state.copyWith(appStatus: AppStatus.loggedOut)); // Update state *after* cleanup
  }

  Future<void> performLogin(String email, String password) async {
    emit(state.copyWith(appStatus: AppStatus.loading)); // Show loading
    debugPrint("[AppCubit] Attempting login for $email");
    final bool isSuccess = await api.login(email, password);

    if (isSuccess) {
      debugPrint("[AppCubit] Login successful. Loading files...");
      // --- Trigger file load AFTER successful login ---
      await filesCubit.loadFolder(''); // Reload root folder
      // --- End Trigger ---
      emit(state.copyWith(appStatus: AppStatus.loggedIn)); // Set final state
      debugPrint("[AppCubit] State set to loggedIn.");
      // Optionally trigger UserCubit profile load here too
      // context.read<UserCubit>().loadUserProfile(); // Needs context or UserCubit injection
    } else {
      debugPrint("[AppCubit] Login failed.");
      // Ensure cleanup on failed login attempt
      await api.logout();
      filesCubit.clearFiles();
      emit(state.copyWith(appStatus: AppStatus.loggedOut)); // Revert to loggedOut
    }
  }

  void stateChanged (AppStatus appStatus) {
    emit(state.copyWith(appStatus: appStatus));
  }
}
