import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/frontend/home_screen/src/files/components/rename_dialog.dart';
import 'package:micki_nas/frontend/home_screen/src/files/cubit/files_cubit.dart';

class Submenu extends StatelessWidget {
  final String path;
  const Submenu({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'rename':
            showDialog<String>(
              context: context,
              builder: (BuildContext context) {
                return RenameDialog(oldName: path.split('/').last);
              },
            ).then((newName) async {
              if (newName != null && newName.isNotEmpty) {
                // Handle the new name (e.g., perform the rename operation)
                if (context.mounted) {
                  await context.read<APIRepository>().renameItem(path, newName);
                  if(context.mounted) {
                    context.read<FilesCubit>().loadFolder(context.read<FilesCubit>().state.path);
                  }
                }
              }
            });
            break;
          case 'delete':
            await context.read<APIRepository>().deleteItem(path);
            if (context.mounted) {
              if (path.contains('/')) {
                context.read<FilesCubit>().loadFolder(path.split('/').removeLast());
              }
              else {
                context.read<FilesCubit>().loadFolder('');
              }
            }

            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }
}
