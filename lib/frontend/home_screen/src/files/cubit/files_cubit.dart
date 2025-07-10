import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/repositories/API.dart';
import '../../../../../core/repositories/models/cloud_item.dart';
import 'package:path/path.dart' as p;
part 'files_state.dart';

enum FilesStatus {
  loading,
  finished,
  failed,
}

class FilesCubit extends Cubit<FilesState> {
  final APIRepository api;

  FilesCubit({required this.api})
      : super(FilesState(path: '', items: [], isLoading: false));

  Future<void> loadFolder(
      String path, {
        String? userId,       // ← optional *named* parameter
      }) async {
    emit(state.copyWith(isLoading: true));


    try {
      final items = await api.fetchCloud(path: path, userId: api.userId);

      emit(state.copyWith(
        path: path,
        userId: api.userId,   // keep it in the Cubit’s state
        items: items,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void clearFiles() {
    debugPrint('[FilesCubit] Clearing files state.');
    // Emit the defined initial state to reset everything.
    emit(state.copyWith(items: [], userId: null, isLoading: false, path: ''));
  }

  void statusChanged (bool isLoading) {
    emit(state.copyWith(
      isLoading: isLoading
    ));
  }

  void goBack() {
    final newPath = p.dirname(state.path);
    loadFolder(newPath == '.' ? '' : newPath);
  }
}
