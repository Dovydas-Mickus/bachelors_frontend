import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/frontend/home_screen/layout.dart';
import 'package:micki_nas/frontend/home_screen/src/files/cubit/files_cubit.dart';
import 'package:micki_nas/frontend/home_screen/src/files/files.dart';
import 'package:micki_nas/frontend/home_screen/src/header/header.dart';
import 'package:micki_nas/frontend/home_screen/src/left_side_bar/left_side_bar.dart';
import 'package:micki_nas/frontend/home_screen/src/right_side_bar/right_side_bar.dart';
import 'package:micki_nas/frontend/user_cubit/user_cubit.dart';

class HomeScreen extends StatelessWidget {
  final String? userId;
  const HomeScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final Widget header = Header();
    final Widget leftSide = LeftSideBar();
    final Widget mainPart = Files(userId: context.read<APIRepository>().userId);
    final Widget rightSide = RightSideBar();

    return BlocBuilder<UserCubit, UserState>(builder: (context, state) {
      if (state.isLoaded) {
        return Layout(
          header: header,
          leftSide: leftSide,
          mainPart: mainPart,
          rightSide: rightSide,
          userId: context.read<APIRepository>().userId,
          speedDialChildren: [
            SpeedDialChild(
              label: 'Create folder',
              child: Icon(Icons.create_new_folder),
              onTap: () => _showCreateFolderDialog(context),
            ),
            SpeedDialChild(
              child: Icon(Icons.upload_file),
              label: 'Upload',
              onTap: () async {
                final api = context.read<APIRepository>();
                final messenger =
                    ScaffoldMessenger.of(context); // capture early
                final String uploadPath = context.read<FilesCubit>().state.path;
                final picked = await FilePicker.platform.pickFiles();

                if (picked != null && picked.files.isNotEmpty) {
                  final file = picked.files.first;

                  final success = await api.uploadFile(file, uploadPath);

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? '✅ File uploaded: ${file.name}'
                          : '❌ Upload failed'),
                      backgroundColor: success ? Colors.green : Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  if (context.mounted) {
                    context.read<FilesCubit>().loadFolder(uploadPath);
                  }
                }
              },
            ),
          ],
        );
      } else {
        return Scaffold(
          body: Center(
            child: Column(children: [
      CircularProgressIndicator(),
      ],
          ),
        ));
      }
    });
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    final String currentPath = context.read<FilesCubit>().state.path;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Folder"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Folder name"),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[./\\]')),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Create"),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                String newPath;
                if (currentPath == '') {
                  newPath = name;
                } else {
                  newPath = "$currentPath/$name";
                }

                final repo = context.read<APIRepository>();
                final response = await repo.createFolder(newPath);

                if (response && context.mounted) {
                  context.read<FilesCubit>().loadFolder(currentPath);
                  Navigator.of(context).pop();
                } else {
                  // Optionally show error message
                }
              },
            ),
          ],
        );
      },
    );
  }
}
