import 'package:flutter/material.dart';
import 'package:micki_nas/frontend/home_screen/src/right_side_bar/src/logout_button.dart';
import 'package:micki_nas/frontend/home_screen/src/right_side_bar/src/theme_toggle_button.dart';


class RightSideBar extends StatelessWidget {
  const RightSideBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 40,),
        ThemeToggleButton(),
        SizedBox(height: 10,),
        LogoutButton(),
      ],
    );
  }
}
