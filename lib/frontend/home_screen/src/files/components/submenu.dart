// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/home_screen/src/files/components/share_dialog.dart';

import 'package:universal_html/html.dart' as html;   // ok on all platforms
import 'package:open_file/open_file.dart';          // stubbed on web

import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/frontend/home_screen/src/files/components/rename_dialog.dart';
import 'package:micki_nas/frontend/home_screen/src/files/cubit/files_cubit.dart';
// Import the new share dialog


class Submenu extends StatelessWidget {
  final String path; // Relative path of the item
  final bool isDirectory; // <-- ADDED: Flag to indicate if it's a directory

  const Submenu({
    super.key,
    required this.path,
    required this.isDirectory, // <-- ADDED: Make it required
  });

  @override
  Widget build(BuildContext context) {
    // Get repository instance once if used multiple times
    final apiRepository = context.read<APIRepository>();
    final filesCubit = context.read<FilesCubit>(); // Get FilesCubit if needed for refresh

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: "More options", // Add tooltip
      onSelected: (String value) async { // Make async
        // Hide any existing SnackBars before showing new ones/dialogs
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        switch (value) {
        // ... (Keep cases for rename, delete, download, share as they were) ...
          case 'rename':
            final newName = await showDialog<String>(
              context: context,
              builder: (_) => RenameDialog(oldName: path.split('/').last),
            );
            if (newName != null && newName.trim().isNotEmpty && context.mounted) {
              // Construct the potential new full path to check if it exists
              String currentDir = path.contains('/') ? path.substring(0, path.lastIndexOf('/')) : '';
              String potentialNewPath = currentDir.isEmpty ? newName.trim() : '$currentDir/${newName.trim()}';

              // Optional: Check if an item with the new name already exists in the current view
              // Note: This requires access to the current list of items, usually from the Cubit state
              // bool exists = filesCubit.doesItemExist(potentialNewPath); // You'd need to implement this in FilesCubit
              // if (exists) {
              //    ScaffoldMessenger.of(context).showSnackBar(
              //       SnackBar(content: Text("❌ An item named '${newName.trim()}' already exists."))
              //    );
              //   return; // Stop if it exists
              // }

              bool success = await apiRepository.renameItem(path, newName.trim());
              if (context.mounted) {
                if (success) {
                  // Reload the PARENT directory after rename/delete
                  String parentPath = path.contains('/') ? path.substring(0, path.lastIndexOf('/')) : '';
                  filesCubit.loadFolder(parentPath);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Renamed successfully"))
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("❌ Failed to rename item"))
                  );
                }
              }
            }
            break;
          case 'delete':
          // Optional: Add a confirmation dialog for delete too
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: Text('Confirm Delete'),
                  content: Text('Are you sure you want to delete "${path.split('/').last}"? This action cannot be undone.'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.of(dialogContext).pop(false), // Return false on cancel
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text('Delete'),
                      onPressed: () => Navigator.of(dialogContext).pop(true), // Return true on confirm
                    ),
                  ],
                );
              },
            ) ?? false; // Default to false if dialog is dismissed

            if (confirmed && context.mounted) {
              bool success = await apiRepository.deleteItem(path);
              if (context.mounted) { // Check context again after await
                if (success) {
                  // Reload the PARENT directory after rename/delete
                  String parentPath = path.contains('/') ? path.substring(0, path.lastIndexOf('/')) : '';
                  filesCubit.loadFolder(parentPath);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Item deleted"))
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("❌ Failed to delete item"))
                  );
                }
              }
            }
            break;
          case 'download':
          // This case should theoretically not be reached if isDirectory is true
          // because the button won't be shown, but we keep the logic.
            if (isDirectory) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ℹ️ Folder download not supported yet.")) // Or specific message
              );
              break; // Prevent attempting download for directory
            }

            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Starting download..."))
            );
            // Use viewingUserId if this item belongs to another user being viewed
            final result = await apiRepository.downloadFile(path, userId: filesCubit.state.userId);
            if (!context.mounted) return; // Check after await
            ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide "Starting..."

            if (result == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ Download failed"))
              );
              break;
            }

            try { // Add try-catch for platform specific actions
              if (kIsWeb) {
                final bytes    = result['bytes'] as Uint8List;
                final fileName = result['filename'] as String;
                final blob = html.Blob([bytes]);
                final url  = html.Url.createObjectUrlFromBlob(blob);
                final anchor = html.document.createElement('a') as html.AnchorElement
                  ..href = url
                  ..download = fileName;
                html.document.body!.append(anchor);
                anchor.click();
                anchor.remove();
                html.Url.revokeObjectUrl(url);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("✅ Download started for $fileName"))
                );
              } else {
                final filePath = result['path'] as String;
                final openResult = await OpenFile.open(filePath);
                // Check result *after* attempting to open
                if (openResult.type == ResultType.done) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("✅ File saved to Downloads & opened: ${result['filename']}")) // Adjusted message
                  );
                } else if (openResult.type == ResultType.noAppToOpen) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("✅ File saved to Downloads. No app found to open it. (${result['filename']})")) // Adjusted message
                  );
                }
                else {
                  debugPrint("OpenFile Error: ${openResult.message}");
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("✅ File saved to Downloads. Error opening: ${openResult.message} (${result['filename']})")) // Adjusted message
                  );
                }
              }
            } catch (e) {
              debugPrint("Error during download processing: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error processing download: $e"))
              );
            }
            break;
          case 'share':
          // This case should theoretically not be reached if isDirectory is true
            if (isDirectory) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ℹ️ Folder sharing not supported yet.")) // Or specific message
              );
              break; // Prevent attempting share for directory
            }
            // Show the dialog to get share options
            final shareParams = await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (_) => ShareOptionsDialog(
                filePath: path,
                apiRepository: apiRepository,
                // Pass viewingUserId if needed by the dialog/API
              ),
            );

            if (shareParams != null && context.mounted) {
              // User confirmed options, call API
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Generating share link..."))
              );

              try {
                final String? shareUrl = await apiRepository.createShareLink(
                  filePath: path, // Already have this
                  shareType: shareParams['shareType'] as String,
                  targetEmail: shareParams['targetEmail'] as String?,
                  targetTeamId: shareParams['targetTeamId'] as String?,
                  durationDays: shareParams['durationDays'] as int?,
                  allowDownload: shareParams['allowDownload'] as bool?,
                  // Pass viewingUserId if the API needs it to know whose file is being shared
                );

                if (!context.mounted) return; // Check after await
                ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide generating message

                if (shareUrl != null) {
                  await showShareLinkDialog(context, shareUrl);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("❌ Failed to generate share link"))
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ Error generating link: $e"))
                );
              }
            } else {
              // Optional: Log cancellation or do nothing
              // debugPrint("Share dialog cancelled or returned null.");
            }
            break; // End of 'share' case

        } // End switch
      }, // End onSelected
      // --- MODIFIED itemBuilder ---
      itemBuilder: (BuildContext popupContext) {
        final List<PopupMenuEntry<String>> items = []; // Start with an empty list

        // --- Conditionally add Share and Download ---
        if (!isDirectory) { // Only add if it's NOT a directory
          items.add(_menuEntry(popupContext, 'share', Icons.share_outlined, 'Share'));
          // Consider adding a divider here if you want separation *between* share and download
          // items.add(const PopupMenuDivider());
          items.add(_menuEntry(popupContext, 'download', Icons.download_outlined, 'Download'));
        }
        // --- End Conditional Items ---


        // Add Rename. Add a divider *before* it ONLY if share/download were added.
        if (!isDirectory) {
          items.add(const PopupMenuDivider());
        }
        items.add(_menuEntry(popupContext, 'rename', Icons.drive_file_rename_outline, 'Rename'));

        // Always add divider before delete
        items.add(const PopupMenuDivider());
        items.add(_menuEntry(popupContext, 'delete', Icons.delete_outline, 'Delete', color: Colors.redAccent));

        return items; // Return the constructed list
      },
    );
  }

  // Helper function for creating menu entries remains the same
  PopupMenuItem<String> _menuEntry(BuildContext context, String value, IconData icon, String label, {Color? color}) =>
      PopupMenuItem<String>(
        value: value,
        child: Row(children: [
          Icon(icon, color: color ?? Theme.of(context).iconTheme.color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color)),
        ]),
      );
}