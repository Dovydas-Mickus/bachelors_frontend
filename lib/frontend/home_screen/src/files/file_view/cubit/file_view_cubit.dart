import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';

import '../../../../../../core/repositories/API.dart';

part 'file_view_state.dart';

class FileViewCubit extends Cubit<FileViewState> {
  final APIRepository repo;

  FileViewCubit({required this.repo}) : super(FileViewState());

  Future<void> loadFile(String path) async {
    emit(state.copyWith(isLoading: true));

    final result = await repo.fetchFileBytes(path);
    if (result != null) {
      emit(FileViewState(
        isLoading: false,
        fileBytes: result['bytes'],
        contentType: result['contentType'],
      ));
    } else {
      emit(state.copyWith(isLoading: false));
    }
  }
}
