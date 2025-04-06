import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/core/repositories/API.dart';

import '../../../../main_screen/cubit/app_cubit.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: () {
      context.read<APIRepository>().logout;
      context.read<AppCubit>().stateChanged(AppStatus.loggedOut);
    }, child: Text('Logout'));
  }
}
