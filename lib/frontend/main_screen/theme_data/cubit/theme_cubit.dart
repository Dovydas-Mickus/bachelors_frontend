import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(themeMode: ThemeMode.light)) {
    _loadTheme(); // load on init
  }

  static const _themeKey = 'theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeKey);

    if (stored != null) {
      final mode = ThemeMode.values.firstWhere(
            (e) => e.toString() == stored,
        orElse: () => ThemeMode.light,
      );
      emit(ThemeState(themeMode: mode));
    }
  }

  Future<void> themeChanged() async {
    final newMode = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    emit(state.copyWith(themeMode: newMode));
    await Future.delayed(Duration(milliseconds: 220));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, newMode.toString());
  }
}
