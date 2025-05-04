// --- In LogoutButton ---
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// REMOVE direct API import if not needed: import 'package:micki_nas/core/repositories/API.dart';
import '../../../../main_screen/cubit/app_cubit.dart'; // Keep AppCubit import

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // Make onPressed async
      onPressed: () async {
        // Call the orchestrated logout method in AppCubit
        // This handles loading state, API call, file clearing, and final state update
        await context.read<AppCubit>().performLogout();

        // --- REMOVE these lines - AppCubit handles them now ---
        // context.read<APIRepository>().logout(); // Don't call directly
        // context.read<AppCubit>().stateChanged(AppStatus.loggedOut); // Don't call directly
        // --- End Removal ---
      },
      child: const Text('Logout'),
    );
  }
}