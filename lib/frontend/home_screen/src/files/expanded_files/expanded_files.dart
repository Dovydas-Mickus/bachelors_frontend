
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import '../../../../../core/repositories/API.dart';
import '../cubit/files_cubit.dart';
import '../file_view/file_view.dart';

class ExpandedFiles extends StatelessWidget {
  final String path;
  const ExpandedFiles({super.key, this.path = ''});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilesCubit, FilesState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final sortedItems = [...state.items]
          ..sort((a, b) {
            if (a.isDirectory && !b.isDirectory) return -1;
            if (!a.isDirectory && b.isDirectory) return 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });


        return Column(
          children: [
            if (state.path.isNotEmpty)
              ListTile(
                leading: Icon(Icons.arrow_back),
                title: Text("Back"),
                onTap: () => context.read<FilesCubit>().goBack(),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: sortedItems.length,
                itemBuilder: (context, index) {
                  final item = sortedItems[index];
                  return ListTile(
                    leading: Icon(item.isDirectory ? Icons.folder : Icons.insert_drive_file),
                    title: Text(
                      item.isDirectory
                          ? item.name
                          : "${p.basenameWithoutExtension(item.name)}.${p.extension(item.name).replaceFirst('.', '')}",
                    ),
                    subtitle: item.isDirectory ? null : Text("${item.size ?? 0} bytes"),
                    onTap: item.isDirectory
                        ? () {
                      final newPath = state.path.isEmpty
                          ? item.name
                          : "${state.path}/${item.name}";
                      context.read<FilesCubit>().loadFolder(newPath);
                    }
                        : () {
                      final fullPath = state.path.isEmpty
                          ? item.name
                          : item.name;

                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: "File viewer",
                        transitionDuration: const Duration(milliseconds: 150),
                        pageBuilder: (context, anim1, anim2) {
                          return Scaffold(
                            body: SafeArea(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width, // Force full screen width
                                child: FileView(
                                  path: fullPath,
                                  repo: context.read<APIRepository>(),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
