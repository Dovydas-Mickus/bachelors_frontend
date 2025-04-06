import 'package:flutter/material.dart';

import '../../../../core/constants.dart';
import 'expanded_files/expanded_files.dart';


class Files extends StatelessWidget {
  const Files({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > CONSTRAINTS_BREAKPOINT) {
            return ExpandedFiles();
          } else {
            return ExpandedFiles();
          }
        },
    );
  }
}
