import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/repositories/API.dart';

class UploadButton extends StatelessWidget {
  final String uploadPath; // relative to root (e.g. '' or 'docs')

  const UploadButton({super.key, this.uploadPath = ''});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.upload_file),
      label: const Text("Upload File"),
      onPressed: () async {
        final picked = await FilePicker.platform.pickFiles();

        if (picked != null && picked.files.isNotEmpty) {
          final file = picked.files.first;
          final api = context.read<APIRepository>();

          final success = await api.uploadFile(file, uploadPath);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? '✅ File uploaded: ${file.name}'
                  : '❌ Upload failed'),
              backgroundColor: success ? Colors.green : Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
}
