import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/home_screen/src/files/cubit/files_cubit.dart';

import '../../../../../core/repositories/API.dart';

class UploadButton extends StatelessWidget {

  const UploadButton({super.key});

  @override
  Widget build(BuildContext context) {

    return ElevatedButton.icon(
      icon: const Icon(Icons.upload_file),
      label: const Text("Upload File"),
      onPressed: () async {
        final api = context.read<APIRepository>();
        final messenger = ScaffoldMessenger.of(context); // capture early
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
          if(context.mounted) {
            context.read<FilesCubit>().loadFolder(uploadPath);
          }
        }
      },
    );
  }
}
