import 'package:flutter/material.dart';
import 'package:micki_nas/frontend/home_screen/src/left_side_bar/src/create_folder_button.dart';

import 'src/upload_button.dart';

class LeftSideBar extends StatelessWidget {
  const LeftSideBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 40,),
        UploadButton(),
        SizedBox(height: 10,),
        CreateFolderButton(),

      ],
    );
  }
}
