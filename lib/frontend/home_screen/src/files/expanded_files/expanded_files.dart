import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/home_screen/src/files/components/submenu.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import '../../../../../core/repositories/API.dart';
import '../cubit/files_cubit.dart';
import '../file_view/file_view.dart';

class ExpandedFiles extends StatelessWidget {
  final String path;
  final String? userId;
  const ExpandedFiles({super.key, this.path = '', this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilesCubit, FilesState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
              child:               CircularProgressIndicator(),
          );
        }

        final sortedItems = [...state.items]..sort((a, b) {
            if (a.isDirectory && !b.isDirectory) return -1;
            if (!a.isDirectory && b.isDirectory) return 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

        return Column(
          children: [
            SizedBox(
              height: 30,
            ),
            if (state.path.isNotEmpty)
              ListTile(
                leading: Icon(Icons.arrow_back),
                title: Text("Back"),
                onTap: () => context.read<FilesCubit>().goBack(),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), // Add bottom padding
                itemCount: sortedItems.length,
                itemBuilder: (context, index) {
                  final item = sortedItems[index];
                  return ListTile(
                    leading: Icon(
                      item.isDirectory ? Icons.folder : Icons.insert_drive_file,
                      color: Colors.green.shade500,
                    ),
                    trailing: Submenu(
                      path: sortedItems[index].name,
                      isDirectory: sortedItems[index].isDirectory,
                    ),
                    title: Text(
                      item.isDirectory
                          ? item.name
                          : "${p.basenameWithoutExtension(item.name)}.${p.extension(item.name).replaceFirst('.', '')}",
                    ),
                    subtitle: item.isDirectory ? null : Text("${item.size ?? 0} bytes"),
                    onTap: item.isDirectory
                        ? () {
                      final newPath = item.name;
                      context.read<FilesCubit>().loadFolder(
                        newPath,
                        userId: context.read<APIRepository>().userId,
                      );
                    }
                        : () {
                      final fullPath =
                      state.path.isEmpty ? item.name : item.name;

                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: "File viewer",
                        transitionDuration: const Duration(milliseconds: 150),
                        pageBuilder: (context, anim1, anim2) {
                          return FileView(
                            path: fullPath,
                            name: item.name,
                            repo: context.read<APIRepository>(),
                            userId: context.read<APIRepository>().userId,
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
