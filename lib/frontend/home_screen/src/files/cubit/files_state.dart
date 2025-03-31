part of 'files_cubit.dart';

class FilesState {
  final String path;
  final List<CloudItem> items;
  final bool isLoading;

  FilesState({
    required this.path,
    required this.items,
    this.isLoading = false,
  });

  FilesState copyWith({
    String? path,
    List<CloudItem>? items,
    bool? isLoading,
  }) {
    return FilesState(
      path: path ?? this.path,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

