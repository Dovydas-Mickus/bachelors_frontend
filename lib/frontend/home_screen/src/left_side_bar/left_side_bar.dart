import 'package:flutter/material.dart';

import 'src/upload_button.dart';

class LeftSideBar extends StatelessWidget {
  const LeftSideBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 40,),
        UploadButton(),
      ],
    );
  }
}
