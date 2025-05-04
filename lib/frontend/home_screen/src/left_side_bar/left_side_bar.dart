import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/home_screen/src/left_side_bar/src/create_folder_button.dart';

import '../../../main_screen/cubit/app_cubit.dart';
import 'src/upload_button.dart';

class LeftSideBar extends StatelessWidget {
  const LeftSideBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Column(
          children: [
            SizedBox(
              height: 40,
            ),
            SizedBox(width: 150, child: UploadButton()),
            SizedBox(
              height: 10,
            ),
            SizedBox(width: 150, child: CreateFolderButton()),
          ],
        );
      },
    );
  }
}
