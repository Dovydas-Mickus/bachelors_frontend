import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/home_screen/src/files/cubit/files_cubit.dart';
import 'package:micki_nas/frontend/main_screen/theme_data/cubit/theme_cubit.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: () async {
      context.read<FilesCubit>().statusChanged(true);
      await context.read<ThemeCubit>().themeChanged();
      if(context.mounted) {
        context.read<FilesCubit>().statusChanged(false);
      }
    }, child: Text('Change theme'));
  }
}

