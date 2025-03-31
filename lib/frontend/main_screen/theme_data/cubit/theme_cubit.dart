import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState(themeMode: ThemeMode.light));

  void themeChanged() {
    if (state.themeMode == ThemeMode.light) {
      emit(state.copyWith(themeMode: ThemeMode.dark));
    }
    else {
      emit(state.copyWith(themeMode: ThemeMode.light));
    }
  }
}
