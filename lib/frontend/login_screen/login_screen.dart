import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/login_screen/inputs/email_field.dart';
import 'package:micki_nas/frontend/login_screen/inputs/password_field.dart';

import '../../core/repositories/API.dart';
import '../main_screen/cubit/app_cubit.dart';
import 'cubit/login_cubit.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _submitLogin(BuildContext context) async {
    final loginCubit = context.read<LoginCubit>();
    final appCubit = context.read<AppCubit>();
    final apiRepository = context.read<APIRepository>();

    final email = loginCubit.state.email;
    final password = loginCubit.state.password;
    appCubit.stateChanged(AppStatus.loading);
    final isSuccess = await apiRepository.login(email, password);

    appCubit.stateChanged(isSuccess ? AppStatus.loggedIn : AppStatus.loggedOut);
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
