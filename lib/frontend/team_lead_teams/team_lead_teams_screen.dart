// lib/frontend/team_lead_teams_screen/team_lead_teams_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/frontend/team_lead_teams/team_members_screen.dart';
// Import the new members screen

import '../../core/repositories/models/team.dart';
import 'cubit/team_lead_teams_cubit.dart';

class TeamLeadTeamsScreen extends StatelessWidget {
  const TeamLeadTeamsScreen({super.key});

  // --- Navigation Handler ---
  void _navigateToTeamMembers(BuildContext context, Team team) {
    // The 'team' object fetched by the Cubit should already contain the user list
    // based on the Team.fromJsonGetAllTeams or similar parser.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeamMembersScreen(
          team: team, // Pass the selected team object
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = TeamLeadTeamsCubit(
          api: context.read<APIRepository>(),
          // TODO: If you need to filter teams by the current user ID:
          // You'll need access to the logged-in user's state here.
          // Example using a hypothetical UserCubit:
          // userId: context.read<UserCubit>().state.id, // Assuming UserCubit holds user info
        );
        cubit.loadTeams();
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your Teams'),
          actions: [
            BlocBuilder<TeamLeadTeamsCubit, TeamLeadTeamsState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: state.isLoading
                      ? null
                      : () => context.read<TeamLeadTeamsCubit>().refreshTeams(),
                  tooltip: 'Refresh Teams',
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<TeamLeadTeamsCubit, TeamLeadTeamsState>(
          builder: (context, state) {
            // --- Loading State ---
            if (state.isLoading && state.teams.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // --- Error State ---
            if (state.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${state.errorMessage}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<TeamLeadTeamsCubit>().loadTeams(),
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              );
            }

            // --- Empty State ---
            if (state.teams.isEmpty && !state.isLoading) {
              return const Center(
                child: Text(
                  'No teams found.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            // --- Data Loaded State ---
            return RefreshIndicator(
              onRefresh: () => context.read<TeamLeadTeamsCubit>().refreshTeams(),
              child: ListView.builder(
                itemCount: state.teams.length,
                itemBuilder: (context, index) {
                  final team = state.teams[index];
                  // Simple subtitle showing member count
                  final subtitleText = '${team.members.length} member(s)';

                  return ListTile(
                    leading: const Icon(Icons.group_work), // Team icon
                    title: Text(team.name),
                    subtitle: Text(subtitleText), // Add more details if needed
                    // Add onTap to navigate to the members screen
                    onTap: () => _navigateToTeamMembers(context, team), // <--- ADD THIS
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}