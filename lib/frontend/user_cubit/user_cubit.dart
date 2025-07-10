import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/core/repositories/API.dart';

part 'user_state.dart';


class UserCubit extends Cubit<UserState> {
  final APIRepository api;

  // Define the clear initial state
  static const UserState initialState = UserState(
    // user: null, // Use a nullable User object instead of individual fields
    firstName: '',
    lastName: '',
    email: '',
    role: '',
    isLoading: false, // Start not loading
    isLoaded: false,  // Start not loaded
    errorMessage: null,
  );

  UserCubit({required this.api}) : super(initialState);

  Future<void> loadUserProfile() async {
    debugPrint("[UserCubit] loadUserProfile: Starting...");
    // 1. Emit Loading State
    emit(state.copyWith(isLoading: true, isLoaded: false, errorMessage: null)); // Indicate loading start, reset loaded/error

    try {
      debugPrint("[UserCubit] loadUserProfile: Calling api.getProfile()...");
      final profileData = await api.getProfile();
      debugPrint("[UserCubit] loadUserProfile: api.getProfile() returned: ${profileData != null ? 'Data received' : 'null'}");

      if (profileData != null) {
        // 2. Emit Success State
        emit(state.copyWith(
          firstName: profileData['first_name'] ?? '', // Use null safety
          lastName: profileData['last_name'] ?? '',
          email: profileData['email'] ?? '',
          role: profileData['role'] ?? '',
          isLoading: false, // Loading finished
          isLoaded: true,   // Data is loaded
          errorMessage: null, // Clear error on success
        ));
        debugPrint("[UserCubit] loadUserProfile: Emitted SUCCESS state.");
      } else {
        // 3. Emit Failure State (Profile not found but API call succeeded)
        debugPrint("[UserCubit] loadUserProfile: Profile data is null. Emitting failure/initial state.");
        // Option A: Reset to initial state (simplest)
        emit(initialState.copyWith(errorMessage: "Failed to load profile (not found)."));
        // Option B: Keep isLoaded false but set error message
        // emit(state.copyWith(isLoading: false, isLoaded: false, errorMessage: "Failed to load profile (not found)."));
      }
    } catch (e, stackTrace) {
      // 4. Emit Error State (Exception occurred)
      final errorMsg = "Error loading profile: $e";
      debugPrint("[UserCubit] loadUserProfile: Exception caught. Emitting error state.");
      debugPrint(stackTrace.toString());
      emit(state.copyWith(
        isLoading: false, // Loading finished (with error)
        isLoaded: false,  // Data is NOT loaded correctly
        errorMessage: errorMsg,
      ));
    }
    debugPrint("[UserCubit] loadUserProfile: Finished.");
  }

  /// Resets the cubit to its initial state. Called on logout.
  void clearUser() {
    debugPrint("[UserCubit] Clearing user state.");
    emit(initialState); // Emit the defined initial state
  }
}
