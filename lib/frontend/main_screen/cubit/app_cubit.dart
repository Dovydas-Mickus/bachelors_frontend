import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/API.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {

  final APIRepository api;

  AppCubit({required this.api}) : super(AppState(
    appStatus: AppStatus.loading,
  )) {
   _initState();
  }

  Future<void> _initState() async {
    emit(state.copyWith(appStatus: AppStatus.loading));
    if (await api.refreshAccessToken()) {
      emit(state.copyWith(appStatus: AppStatus.loggedIn));
    } else {
      emit(state.copyWith(appStatus: AppStatus.loggedOut));
    }
  }

  void stateChanged (AppStatus appStatus) {
    emit(state.copyWith(appStatus: appStatus));
  }
}
