import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/home_screen/src/files/cubit/files_cubit.dart';
import 'package:micki_nas/frontend/login_screen/inputs/email_field.dart';
import 'package:micki_nas/frontend/login_screen/inputs/password_field.dart';
import 'package:micki_nas/frontend/user_cubit/user_cubit.dart';

import '../../core/repositories/API.dart';
import '../main_screen/cubit/app_cubit.dart';
import 'cubit/login_cubit.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _submitLogin(BuildContext context) async {
    final loginCubit = context.read<LoginCubit>();
    final appCubit = context.read<AppCubit>();
    final userCubit = context.read<UserCubit>(); // Get UserCubit instance
    final filesCubit = context.read<FilesCubit>(); // Get FilesCubit instance
    final apiRepository = context.read<APIRepository>();

    final email = loginCubit.state.email;
    final password = loginCubit.state.password;

    // 1. Indicate loading
    appCubit.stateChanged(AppStatus.loading); // Assuming this updates UI

    // 2. Attempt API Login
    // IMPORTANT: Assuming apiRepository.login returns bool for now.
    // If it returns Map?, change this check to `loginResult != null`
    final bool loginSuccess = await apiRepository.login(email, password);



    if (loginSuccess) {
      // 3. Login API succeeded, now load the definitive profile
      debugPrint("Login API success. Loading user profile...");
      await userCubit.loadUserProfile(); // This emits loading/loaded/error states

      // 4. Check if profile load actually succeeded
      if (userCubit.state.isLoaded) {
        debugPrint("User profile loaded successfully. Loading initial files...");
        // 5. Load initial files *after* profile is confirmed loaded
        await filesCubit.loadFolder(''); // Now it's safer to load files


        // 6. Update global app state to loggedIn *after* everything succeeds
        debugPrint("Setting AppStatus to loggedIn.");
        appCubit.stateChanged(AppStatus.loggedIn);

      } else {
        // Profile load failed even though login API succeeded
        debugPrint("Login API success, but profile load failed. Error: ${userCubit.state.errorMessage}");
        // Update global app state to reflect failure
        appCubit.stateChanged(AppStatus.loggedOut); // Or a specific error state
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login succeeded but failed to load profile: ${userCubit.state.errorMessage ?? 'Unknown error'}")),
        );
        // Optionally clear user cubit state again?
        // userCubit.clearUser();
      }
    } else {
      // Login API failed
      debugPrint("Login API failed.");
      if (!context.mounted) return;
      // Update global app state
      appCubit.stateChanged(AppStatus.loggedOut);
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed. Please check credentials.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(),
      child: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(''),
            ),
            body: Align(
              alignment: Alignment(0, -0.3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 40,
                    ),
                  ),
                  SizedBox(height: 50),
                  SizedBox(
                    width: 300,
                    child: EmailField(),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: 300,
                    child: PasswordField(
                      // When the user presses enter in the password field, submit the login.
                      onFieldSubmitted: (_) => _submitLogin(context),
                    ),
                  ),

                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _submitLogin(context),
                    child: Text('Login'),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
