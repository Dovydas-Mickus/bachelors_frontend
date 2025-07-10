import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/login_screen/inputs/email_field.dart';
import 'package:micki_nas/frontend/login_screen/inputs/password_field.dart';

import '../main_screen/cubit/app_cubit.dart';
import 'cubit/login_cubit.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _submitLogin(BuildContext context) async {
    final state = context.read<LoginState>();

    await context.read<AppCubit>().performLogin(state.email, state.password);
    return;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
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
                SizedBox(height: 30),
                Text(state.errorMessage),
                SizedBox(
                  height: 20,
                ),
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
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () async => await context
                      .read<AppCubit>()
                      .performLogin(state.email, state.password),
                  child: Container(
                    width: 300, // Makes it full-width inside its parent
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 24), // Optional: side spacing
                    decoration: BoxDecoration(
                      color: ColorScheme.of(context).primary,
                      border: Border.all(
                        width: 1,
                        color: Colors.black,
                      ),
                      borderRadius:
                          BorderRadius.circular(25), // Rounded corners
                    ),
                    child: Center(
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: ColorScheme.of(context).onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
