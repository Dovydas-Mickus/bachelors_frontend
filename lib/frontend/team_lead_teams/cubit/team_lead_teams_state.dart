// lib/frontend/team_lead_teams_screen/cubit/team_lead_teams_state.dart
part of 'team_lead_teams_cubit.dart'; // Link to the cubit file

class TeamLeadTeamsState extends Equatable {
  final List<Team> teams;
  final bool isLoading;
  final String? errorMessage; // Optional: Add error handling

  const TeamLeadTeamsState({
    required this.teams,
    this.isLoading = false,
    this.errorMessage,
  });

  // Initial state
  factory TeamLeadTeamsState.initial() {
    return const TeamLeadTeamsState(teams: [], isLoading: false);
  }


  TeamLeadTeamsState copyWith({
    List<Team>? teams,
    bool? isLoading,
    String? errorMessage,
    // Helper to explicitly clear the error
    bool clearError = false,
  }) {
    return TeamLeadTeamsState(
      teams: teams ?? this.teams,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [teams, isLoading, errorMessage];
}