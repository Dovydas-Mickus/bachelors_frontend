import 'package:flutter/material.dart';

class RenameDialog extends StatefulWidget {
  final String oldName;
  const RenameDialog({super.key, required this.oldName});

  @override
  RenameDialogState createState() => RenameDialogState();
}

class RenameDialogState extends State<RenameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.oldName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename File/Folder'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'New name',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.text);
          },
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
