import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/login_screen/cubit/login_cubit.dart';

import '../../../core/repositories/API.dart';
import '../../home_screen/src/files/cubit/files_cubit.dart';
// Make sure to import your UserCubit
import '../../user_cubit/user_cubit.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  final APIRepository api;
  final FilesCubit filesCubit;
  final UserCubit userCubit; // <-- ADD DEPENDENCY
  final LoginCubit loginCubit;

  AppCubit({
    required this.api,
    required this.filesCubit,
    required this.userCubit, // <-- ADD DEPENDENCY
    required this.loginCubit,
  }) : super(const AppState(appStatus: AppStatus.loggedOut)) { // Start as loggedOut
    _checkInitialAuth(); // Check for existing session on app start
  }

  /// Checks for a valid token when the app starts.
  Future<void> _checkInitialAuth() async {
    emit(state.copyWith(appStatus: AppStatus.loading));
    try {
      if (await api.refreshAccessToken()) {
        // Token is valid, now load all necessary data
        await _loadInitialData();
        emit(state.copyWith(appStatus: AppStatus.loggedIn));
      } else {
        // No valid token
        emit(state.copyWith(appStatus: AppStatus.loggedOut));
      }
    } catch (e) {
      // Any failure during initial load leads to logged out state
      emit(state.copyWith(appStatus: AppStatus.loggedOut));
    }
  }

  /// This is the SINGLE SOURCE OF TRUTH for the login flow.
  Future<void> performLogin(String email, String password) async {
    emit(state.copyWith(appStatus: AppStatus.loading));
    try {
      // 1. Authenticate
      final bool isSuccess = await api.login(email, password);
      if (!isSuccess) {
        throw Exception("Invalid Credentials"); // This will be caught below
      }

      // 2. Load all required data for the app to be "ready"
      await _loadInitialData();

      // 3. If all succeeds, set the final state
      emit(state.copyWith(appStatus: AppStatus.loggedIn));
      loginCubit.errorMessageChanged('');
    } catch (e) {
      // CATCH-ALL: Any failure in the `try` block (login, files, user, etc.) lands here.
      debugPrint("[AppCubit] Login flow failed: $e");
      loginCubit.errorMessageChanged('Invalid Credentials');
      await performLogout(); // Reuse logout logic for full cleanup
    }
  }

  /// Helper function to load all data in parallel for speed.
  Future<void> _loadInitialData() async {
    debugPrint("[AppCubit] Loading initial data (files, user profile, cloud)...");
    await Future.wait([
      filesCubit.loadFolder(''),
      userCubit.loadUserProfile(),
      api.fetchCloud(),
    ]);
  }

  /// Cleans up and sets the state to loggedOut.
  Future<void> performLogout() async {
    emit(state.copyWith(appStatus: AppStatus.loading));
    try {
      await api.logout();
    } catch (e) {
      debugPrint("Error during API logout, proceeding anyway: $e");
    } finally {
      // Always clear local data and update state
      filesCubit.clearFiles();
      userCubit.clearUser();
      emit(state.copyWith(appStatus: AppStatus.loggedOut));
    }
  }

// DELETE this method. It is no longer needed and is an anti-pattern.
// void stateChanged (AppStatus appStatus) { ... }
}