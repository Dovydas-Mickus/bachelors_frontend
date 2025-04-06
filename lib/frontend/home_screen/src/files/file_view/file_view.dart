import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/home_screen/src/files/components/pdf_viewer.dart';

import '../../../../../core/repositories/API.dart';
import 'cubit/file_view_cubit.dart';
import 'src/video_player/video_player.dart'; // Adjust path

class FileView extends StatelessWidget {
  final String path;
  final APIRepository repo;

  const FileView({super.key, required this.path, required this.repo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FileViewCubit(repo: repo)..loadFile(path),
      child: BlocBuilder<FileViewCubit, FileViewState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if ((state.fileBytes == null) ||
              state.contentType == null) {
            return const Center(child: Icon(Icons.error, size: 48));
          }

          return Scaffold(
            appBar: AppBar(),
            body: _buildFilePreview(state),
          );
        },
      ),
    );
  }

  Widget _buildFilePreview(FileViewState state) {
    final contentType = state.contentType!;

    if (contentType.startsWith("video/")) {
      return VideoPlayerWidget(bytes: state.fileBytes!,);
    }


    if (state.fileBytes == null) {
      return const Center(child: Text("No file data"));
    }

    final bytes = state.fileBytes!;

    if (contentType.startsWith("image/")) {
      return InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 0.1,
        maxScale: 5.0,
        child: Center(
          child: FittedBox(
            child: Image.memory(bytes),
          ),
        ),
      );
    }

    if (contentType.startsWith("text/") || contentType == "application/json") {
      final text = utf8.decode(bytes, allowMalformed: true);
      return Padding(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: SelectableText(
                text,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (contentType == "application/pdf") {
      return PdfViewerScreen(pdfBytes: bytes);
    }

    return const Center(
      child: Text("Unsupported file type"),
    );
  }
}
