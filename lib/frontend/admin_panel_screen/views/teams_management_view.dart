import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/core/repositories/models/user.dart';
import 'package:micki_nas/frontend/admin_panel_screen/components/add_team_dialog.dart';
import 'package:micki_nas/frontend/admin_panel_screen/components/teams_list.dart';
import 'package:micki_nas/frontend/admin_panel_screen/cubit/admin_cubit.dart';

class TeamsManagementView extends StatelessWidget {
  const TeamsManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the Cubit provided by AdminPanelScreen
    final adminCubit = context.watch<AdminCubit>();
    final apiRepository = context.read<APIRepository>(); // Read API Repo

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Manage Teams", // Adjusted title slightly
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon( // Added icon for consistency
                icon: const Icon(Icons.add),
                label: const Text("Create Team"),
                onPressed: () async {
                  // Use the user list from the Cubit state if available
                  if (adminCubit.state.users.isEmpty) {
                    // Optionally trigger loading users if not loaded yet
                    // await adminCubit.loadUsers();
                    // Re-check after loading attempt
                    if (adminCubit.state.users.isEmpty && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("⚠️ User list unavailable.")),
                      );
                      return;
                    }
                  }
                  final List<User> allUsers = adminCubit.state.users;


                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) => AddTeamDialog(allUsers: allUsers),
                  );

                  if (result != null && context.mounted) {
                    final name = result['name'] as String?;
                    final leadEmail = result['lead'] as String?;
                    final memberEmails = result['emails'] as List<String>?;

                    if (name == null || leadEmail == null || memberEmails == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("❌ Invalid data from dialog.")),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Creating team...")),
                    );

                    final success = await apiRepository.createTeam(
                        name: name,
                        lead: leadEmail,
                        emails: memberEmails);

                    if (success && context.mounted) {
                      adminCubit.loadTeams(); // Use cubit instance
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ Team created successfully")),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("❌ Failed to create team")),
                      );
                    }
                  }
                },
              )
            ],
          ),
        ),
        const Divider(),
        Expanded(
          // Use BlocBuilder specifically for the list part
          child: BlocBuilder<AdminCubit, AdminState>(
            // Optional: buildWhen to only rebuild if teams change
            buildWhen: (previous, current) => previous.teams != current.teams || previous.isLoading != current.isLoading,
            builder: (context, state) {
              if (state.isLoading) {
                // Consider a more specific loading indicator if only teams are loading
                return const Center(child: CircularProgressIndicator());
              }
              if (state.teams.isEmpty) {
                return const Center(child: Text("No teams found."));
              }
              return TeamsList(teams: state.teams);
            },
          ),
        ),
      ],
    );
  }
}