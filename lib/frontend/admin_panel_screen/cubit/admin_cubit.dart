import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/core/repositories/models/team.dart';

import '../../../core/repositories/models/user.dart';

part 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final APIRepository api;

  AdminCubit({required this.api}) : super(const AdminState(teams: [], users: [], isLoading: true));

  Future<void> loadTeams() async {
    emit(state.copyWith(isLoading: true));

    final teams = await api.getAllTeams();

    emit(state.copyWith(teams: teams, isLoading: false));
  }

  Future<void> loadUsers() async {
    emit(state.copyWith(isLoading: true));

    final users = await api.getUsers();

    emit(state.copyWith(users: users, isLoading: false));
  }
}

