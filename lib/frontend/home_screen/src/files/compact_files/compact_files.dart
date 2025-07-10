import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/repositories/API.dart';
import '../../../../../core/repositories/models/cloud_item.dart';


class CompactFiles extends StatelessWidget {
  const CompactFiles({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CloudItem>>(
      future: context.read<APIRepository>().fetchCloud(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data!;
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: Icon(item.isDirectory ? Icons.folder : Icons.insert_drive_file),
              title: Text(item.name),
              subtitle: item.isDirectory ? null : Text("${item.size ?? 0} bytes"),
            );
          },
        );
      },
    );
  }
}
