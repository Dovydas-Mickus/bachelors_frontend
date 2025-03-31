part of 'file_view_cubit.dart';


class FileViewState {
  final bool isLoading;
  final Uint8List? fileBytes;
  final String? contentType;

  FileViewState({
    this.isLoading = true,
    this.fileBytes,
    this.contentType,
  });

  FileViewState copyWith({
    bool? isLoading,
    Uint8List? fileBytes,
    String? contentType,
  }) {
    return FileViewState(
      isLoading: isLoading ?? this.isLoading,
      fileBytes: fileBytes ?? this.fileBytes,
      contentType: contentType ?? this.contentType,
    );
  }
}

