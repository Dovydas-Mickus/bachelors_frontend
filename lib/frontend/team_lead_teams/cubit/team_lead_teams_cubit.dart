// lib/frontend/team_lead_teams_screen/cubit/team_lead_teams_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/core/repositories/models/team.dart';

part 'team_lead_teams_state.dart'; // Link to the state file

class TeamLeadTeamsCubit extends Cubit<TeamLeadTeamsState> {
  final APIRepository api;
  // You might need the current user's ID if you want to show *specific* teams
  // final String userId;

  TeamLeadTeamsCubit({
    required this.api,
    // required this.userId, // Uncomment if filtering by lead
  }) : super(TeamLeadTeamsState.initial()); // Start with initial state

  Future<void> loadTeams() async {
    // Set loading state and clear previous errors
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      // Fetch all teams (adjust if you need specific teams for the lead)
      // Example: final teams = await api.getTeamsForLead(userId);
      final teams = await api.getAllTeams(); // Using the existing method for now

      // Emit success state with fetched teams
      emit(state.copyWith(teams: teams, isLoading: false));
    } catch (e) {
      // Emit error state
      emit(state.copyWith(isLoading: false, errorMessage: 'Failed to load teams: ${e.toString()}'));
      // You might want more sophisticated error handling/logging here
    }
  }

  // Optional: Add methods for specific actions like refreshing
  Future<void> refreshTeams() async {
    await loadTeams(); // Simply reload the teams
  }
}