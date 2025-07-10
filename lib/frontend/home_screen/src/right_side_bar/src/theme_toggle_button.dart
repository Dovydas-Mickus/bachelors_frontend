import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/home_screen/src/files/cubit/files_cubit.dart';
import 'package:micki_nas/frontend/main_screen/theme_data/cubit/theme_cubit.dart';
// Make sure to import your ThemeState class

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Use BlocBuilder to listen for changes in the ThemeCubit
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        // 2. Build the ListTile using the current theme 'state'
        return ListTile(
          // 3. Add an icon to the 'leading' property
          leading: Icon(
            // 4. Choose the icon based on the current theme state
            //    (Assuming your state has an 'isDarkMode' property)
            state.themeMode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          ),
          // Your original onTap logic remains the same
          onTap: () async {
            context.read<FilesCubit>().statusChanged(true);
            await context.read<ThemeCubit>().themeChanged();
            if (context.mounted) {
              context.read<FilesCubit>().statusChanged(false);
            }
          },
          // The title is now simpler without the redundant Center widget
          title: const Text('Change Theme'),
        );
      },
    );
  }
}