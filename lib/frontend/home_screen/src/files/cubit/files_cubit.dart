import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/repositories/API.dart';
import '../../../../../core/repositories/models/cloud_item.dart';

part 'files_state.dart';

class FilesCubit extends Cubit<FilesState> {
  final APIRepository api;

  FilesCubit({required this.api})
      : super(FilesState(path: '', items: [], isLoading: false));

  Future<void> loadFolder(String path) async {
    emit(state.copyWith(isLoading: true));
    try {
      final items = await api.fetchCloud(path: path);
      emit(FilesState(path: path, items: items, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      // handle error if needed
    }
  }

  void goBack() {
    final parts = state.path.split('/')..removeLast();
    final newPath = parts.join('/');
    loadFolder(newPath);
  }
}
