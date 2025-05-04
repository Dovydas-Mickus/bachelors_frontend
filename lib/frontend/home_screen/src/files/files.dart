import 'package:flutter/material.dart';

import '../../../../core/constants.dart';
import 'expanded_files/expanded_files.dart';


class Files extends StatelessWidget {
  final String? userId;
  const Files({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > CONSTRAINTS_BREAKPOINT) {
            return ExpandedFiles(userId: userId);
          } else {
            return ExpandedFiles(userId: userId);
          }
        },
    );
  }
}
