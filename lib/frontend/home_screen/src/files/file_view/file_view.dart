import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/home_screen/src/files/components/pdf_viewer.dart';
import 'package:micki_nas/frontend/home_screen/src/files/file_view/src/audio_player/audio_player.dart';

import '../../../../../core/repositories/API.dart';
import 'cubit/file_view_cubit.dart';
import 'src/video_player/video_player.dart'; // Adjust path if needed

class FileView extends StatelessWidget {
  final String path;
  final APIRepository repo;
  final String name; // File name passed from previous screen
  final String? userId;

  const FileView({
    super.key,
    required this.path,
    required this.name,
    required this.repo,
    this.userId
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FileViewCubit(repo: repo)..loadFile(path, userId: userId),
      child: BlocBuilder<FileViewCubit, FileViewState>(
        builder: (context, state) {
          Widget bodyContent; // Variable to hold the body content

          if (state.isLoading) {
            bodyContent = const Center(child: CircularProgressIndicator());
          } else if (state.fileBytes == null || state.contentType == null) {
            bodyContent = const Center(
              child: Column( // Provide more context on error
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 10),
                  Text("Failed to load file data."),
                  // Optionally display state.errorMessage if you add it to the state
                ],
              ),
            );
          } else {
            // Pass the state and file name to the builder function
            bodyContent = _buildFilePreview(state, name);
          }

          // Always return Scaffold, change body based on state
          return Scaffold(
            appBar: AppBar(title: Text(name)), // Use the passed file name
            body: bodyContent,
          );
        },
      ),
    );
  }

  // Updated to accept name parameter
  Widget _buildFilePreview(FileViewState state, String fileName) {
    final contentType = state.contentType!;
    final bytes = state.fileBytes!; // Bytes are guaranteed non-null here

    if (contentType.startsWith("video/")) {
      // Assuming VideoPlayerWidget handles null bytes internally if necessary
      return VideoPlayerWidget(bytes: bytes);
    }

    // --- Add Audio Check ---
    if (contentType.startsWith("audio/")) {
      return AudioPlayerWidget(bytes: bytes, fileName: fileName); // Pass bytes and name
    }
    // --- End Audio Check ---

    if (contentType.startsWith("image/")) {
      return InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 0.1,
        maxScale: 5.0,
        child: Center(
          child: FittedBox( // Use FittedBox for better scaling within Center
            fit: BoxFit.contain, // Ensure image fits while maintaining aspect ratio
            child: Image.memory(bytes),
          ),
        ),
      );
    }

    if (contentType.startsWith("text/") || contentType == "application/json") {
      // Use try-catch for decoding as bytes might be invalid UTF-8
      String text;
      try {
        text = utf8.decode(bytes, allowMalformed: true);
      } catch (e) {
        debugPrint("Error decoding text file: $e");
        text = "Error: Could not decode file content as text.";
      }
      return Padding(
        padding: const EdgeInsets.all(16.0), // Adjusted padding
        child: Scrollbar( // Add Scrollbar for long text
          thumbVisibility: true, // Make scrollbar always visible
          child: SingleChildScrollView(
            child: SelectableText( // Make text selectable
              text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ),
        ),
      );
    }

    if (contentType == "application/pdf") {
      return PdfViewerScreen(pdfBytes: bytes);
    }

    // Fallback for unsupported types
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.help_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 10),
            Text("Unsupported file type: $contentType"),
          ],
        )
    );
  }
}