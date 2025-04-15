import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/repositories/API.dart';
import '../../files/cubit/files_cubit.dart';

class CreateFolderButton extends StatelessWidget {
  const CreateFolderButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        _showCreateFolderDialog(context);
      },
      icon: Icon(Icons.create_new_folder),
      label: Text('Create folder'),
    );
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




