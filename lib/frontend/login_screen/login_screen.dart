import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/repositories/API.dart';
import '../main_screen/cubit/app_cubit.dart';
import 'cubit/login_cubit.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(25.0))
                          )
                      ),
                      onChanged: (value) {
                        context.read<LoginCubit>().emailChanged(value);
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25.0))
                        )
                      ),
                      onChanged: (value) {
                        context.read<LoginCubit>().passwordChanged(value);
                      },
                    ),
                  ),
                  ElevatedButton(onPressed: () async {
                    bool isSuccess = await context.read<APIRepository>().login(context.read<LoginCubit>().state.email, context.read<LoginCubit>().state.password);
                    if(isSuccess) {
                      context.read<AppCubit>().stateChanged(AppStatus.loggedIn);
                    } else {
                      context.read<AppCubit>().stateChanged(AppStatus.loggedOut);
                    }
                  }, child: Text('Login'))
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
