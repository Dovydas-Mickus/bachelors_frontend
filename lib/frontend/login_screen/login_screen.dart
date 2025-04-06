import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

    final isSuccess = await apiRepository.login(email, password);

    if (!context.mounted) return;

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
              title: Text('Login Screen'),
            ),
            body: Align(
              alignment: Alignment(0, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25.0)),
                        ),
                      ),
                      onChanged: (value) {
                        context.read<LoginCubit>().emailChanged(value);
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25.0)),
                        ),
                      ),
                      onChanged: (value) {
                        context.read<LoginCubit>().passwordChanged(value);
                      },
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        _submitLogin(context);
                      },
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
