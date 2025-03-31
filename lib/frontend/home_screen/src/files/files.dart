import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants.dart';
import '../../../../core/repositories/API.dart';
import 'cubit/files_cubit.dart';
import 'expanded_files/expanded_files.dart';


class Files extends StatelessWidget {
  const Files({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FilesCubit(api: context.read<APIRepository>())..loadFolder(''),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > CONSTRAINTS_BREAKPOINT) {
            return ExpandedFiles();
          } else {
            return ExpandedFiles();
          }
        },
      ),
    );
  }
}
