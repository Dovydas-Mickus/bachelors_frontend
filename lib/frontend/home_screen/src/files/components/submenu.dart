// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/home_screen/src/files/components/share_dialog.dart';
import 'package:universal_html/html.dart' as html;
import 'package:open_file/open_file.dart';

import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/frontend/home_screen/src/files/components/rename_dialog.dart';
import 'package:micki_nas/frontend/home_screen/src/files/cubit/files_cubit.dart';

class Submenu extends StatelessWidget {
  final String path;
  final bool isDirectory;

  const Submenu({
    super.key,
    required this.path,
    required this.isDirectory,
  });

  @override
  Widget build(BuildContext context) {
    final apiRepository = context.read<APIRepository>();
    final filesCubit = context.read<FilesCubit>();

    return PopupMenuButton<String>(
      color: ColorScheme.of(context).secondary, // Darker, cleaner tone
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 10,
      icon: const Icon(Icons.more_vert),
      tooltip: "More options",
      onSelected: (value) => _handleSelection(
        context,
        value,
        apiRepository,
        filesCubit,
      ),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        if (!isDirectory) {
          items.addAll([
            _menuEntry(context, 'share', Icons.share_outlined, 'Share'),
            _menuEntry(context, 'download', Icons.download_outlined, 'Download'),
            const PopupMenuDivider(),
          ]);
        }

        items.addAll([
          _menuEntry(context, 'rename', Icons.drive_file_rename_outline, 'Rename'),
          const PopupMenuDivider(),
          _menuEntry(context, 'delete', Icons.delete_outline, 'Delete', color: Colors.redAccent),
        ]);

        return items;
      },
    );
  }

  PopupMenuItem<String> _menuEntry(
      BuildContext context,
      String value,
      IconData icon,
      String label, {
        Color? color,
      }) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color ?? ColorScheme.of(context).onSecondary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: color ?? ColorScheme.of(context).onSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _handleSelection(
      BuildContext context,
      String value,
      APIRepository apiRepository,
      FilesCubit filesCubit,
      ) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    switch (value) {
      case 'rename':
        await _handleRename(context, apiRepository, filesCubit);
        break;
      case 'delete':
        await _handleDelete(context, apiRepository, filesCubit);
        break;
      case 'download':
        await _handleDownload(context, apiRepository, filesCubit);
        break;
      case 'share':
        await _handleShare(context, apiRepository, filesCubit);
        break;
    }
  }

  Future<void> _handleRename(
      BuildContext context,
      APIRepository apiRepository,
      FilesCubit filesCubit,
      ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => RenameDialog(oldName: path.split('/').last),
    );

    if (newName?.trim().isEmpty ?? true) return;

    final currentDir = path.contains('/') ? path.substring(0, path.lastIndexOf('/')) : '';
    final success = await apiRepository.renameItem(path, newName!.trim());

    if (!context.mounted) return;

    final message = success
        ? '✅ Renamed successfully'
        : '❌ Failed to rename item';

    if (success) filesCubit.loadFolder(currentDir);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleDelete(
      BuildContext context,
      APIRepository apiRepository,
      FilesCubit filesCubit,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete "${path.split('/').last}" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirmed) return;

    final parent = path.contains('/') ? path.substring(0, path.lastIndexOf('/')) : '';
    final success = await apiRepository.deleteItem(path);

    if (!context.mounted) return;

    final message = success ? '✅ Item deleted' : '❌ Failed to delete item';
    if (success) filesCubit.loadFolder(parent);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleDownload(
      BuildContext context,
      APIRepository apiRepository,
      FilesCubit filesCubit,
      ) async {
    if (isDirectory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ℹ️ Folder download not supported yet.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting download...')),
    );

    final result = await apiRepository.downloadFile(path, userId: filesCubit.state.userId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Download failed')),
      );
      return;
    }

    try {
      if (kIsWeb) {
        final bytes = result['bytes'] as Uint8List;
        final fileName = result['filename'] as String;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);


        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Download started for $fileName')),
        );
      } else {
        final filePath = result['path'] as String;
        final fileName = result['filename'] as String;
        final openResult = await OpenFile.open(filePath);

        final message = switch (openResult.type) {
          ResultType.done => '✅ File saved & opened: $fileName',
          ResultType.noAppToOpen => '✅ Saved. No app to open: $fileName',
          _ => '✅ Saved. Couldn\'t open: ${openResult.message}',
        };

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      debugPrint('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during download: $e')),
      );
    }
  }

  Future<void> _handleShare(
      BuildContext context,
      APIRepository apiRepository,
      FilesCubit filesCubit,
      ) async {
    if (isDirectory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ℹ️ Folder sharing not supported yet.')),
      );
      return;
    }

    final shareParams = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ShareOptionsDialog(
        filePath: path,
        apiRepository: apiRepository,
      ),
    );

    if (shareParams == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating share link...')),
    );

    try {
      final shareUrl = await apiRepository.createShareLink(
        filePath: path,
        shareType: shareParams['shareType'],
        targetEmail: shareParams['targetEmail'],
        targetTeamId: shareParams['targetTeamId'],
        durationDays: shareParams['durationDays'],
        allowDownload: shareParams['allowDownload'],
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (shareUrl != null) {
        await showShareLinkDialog(context, shareUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to generate share link')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error generating link: $e')),
      );
    }
  }
}
