part of 'files_cubit.dart';

class FilesState extends Equatable {
  final String path;
  final List<CloudItem> items;
  final bool isLoading;
  final String? userId;

  const FilesState({
    required this.path,
    required this.items,
    this.isLoading = false,
    this.userId
  });

  FilesState copyWith({
    String? path,
    List<CloudItem>? items,
    bool? isLoading,
    String? userId,
  }) {
    return FilesState(
      path: path ?? this.path,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [path, items, isLoading, userId];
}

