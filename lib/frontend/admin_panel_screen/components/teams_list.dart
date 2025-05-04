import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/core/repositories/API.dart';
// Import the dialog (which also needs updating for edit mode)
import 'package:micki_nas/frontend/admin_panel_screen/components/add_team_dialog.dart';
// Import the Cubit to trigger reloads
import 'package:micki_nas/frontend/admin_panel_screen/cubit/admin_cubit.dart';

import '../../../core/repositories/models/team.dart';
import '../../../core/repositories/models/user.dart';


class TeamsList extends StatelessWidget {
  final List<Team> teams;

  const TeamsList({super.key, required this.teams});

  @override
  Widget build(BuildContext context) {
    // Get instances from context for handlers
    final adminCubit = context.read<AdminCubit>();
    final api = context.read<APIRepository>();

    return ListView.builder(
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];

        // Build subtitle dynamically
        String subtitleText = 'Lead: ${team.lead?.email ?? 'None'} | Members: ${team.members.isNotEmpty ? team.members.length : team.members.length}';

        return ListTile(
          title: Text(team.name),
          subtitle: Text(subtitleText),
          // Keep onTap triggering the edit dialog
          onTap: () async => _editTeam(context, api, adminCubit, team.id),
          // Add the delete button back and wire it up
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Team',
            // Call the specific delete handler
            onPressed: () => _handleDeleteTeam(context, api, adminCubit, team),
          ),
        );
      },
    );
  }

  // --- Edit Team Helper (Existing - Keep As Is) ---
  Future<void> _editTeam(BuildContext context, APIRepository api, AdminCubit adminCubit, String teamId) async {
    // ... (Your existing _editTeam implementation remains unchanged) ...
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Loading team details...")),
    );
    final Team? teamToEdit = await api.getTeam(teamId: teamId);
    if (!context.mounted) return;
    if (teamToEdit == null) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to load team info")),
      );
      return;
    }
    final List<User> allUsers = await api.getUsers();
    if (!context.mounted) return;
    if (allUsers.isEmpty) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Could not fetch users list.")),
      );
      return;
    }
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final String? initialLeadEmail = teamToEdit.lead?.email;
    final List<String> initialMemberEmails = (teamToEdit.members.isNotEmpty
        ? teamToEdit.members
        : teamToEdit.members)
        .map((user) => user.email)
        .toList();
    if(initialLeadEmail != null) {
      initialMemberEmails.remove(initialLeadEmail);
    }
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AddTeamDialog(
        allUsers: allUsers,
        initialName: teamToEdit.name,
        initialLeadEmail: initialLeadEmail,
        initialMemberEmails: initialMemberEmails,
        isEditMode: true,
        teamId: teamId,
      ),
    );
    if (result != null && context.mounted) {
      final String? newName = result['name'] as String?;
      final String? newLeadEmail = result['lead'] as String?;
      final List<String>? addEmails = result['add_emails'] as List<String>?;
      final List<String>? removeEmails = result['remove_emails'] as List<String>?;
      bool nameChanged = newName != null && newName.trim() != teamToEdit.name;
      bool leadChanged = newLeadEmail != null && newLeadEmail != initialLeadEmail;
      bool membersChanged = (addEmails != null && addEmails.isNotEmpty) || (removeEmails != null && removeEmails.isNotEmpty);
      bool hasChanges = nameChanged || leadChanged || membersChanged;
      if (!hasChanges) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ℹ️ No changes detected.")),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updating team..."), duration: Duration(seconds: 30)),
      );
      final success = await api.editTeam(
        teamId: teamId,
        newName: nameChanged ? newName.trim() : null,
        newLeadEmail: leadChanged ? newLeadEmail : null,
        addEmails: addEmails,
        removeEmails: removeEmails,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Team updated successfully")),
        );
        adminCubit.loadTeams();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to update team")),
        );
      }
    } else {
      debugPrint("Edit team dialog cancelled.");
    }
  }
  // --- End _editTeam ---


  // --- NEW: Delete Confirmation Dialog ---
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, Team team) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the team "${team.name}"?\nThis action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Return false: Cancelled
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // Return true: Confirmed
              },
            ),
          ],
        );
      },
    );
  }
  // --- End Delete Confirmation Dialog ---


  // --- NEW: Delete Handler ---
  Future<void> _handleDeleteTeam(BuildContext context, APIRepository api, AdminCubit adminCubit, Team team) async {
    // 1. Show confirmation dialog
    final confirmed = await _showDeleteConfirmationDialog(context, team);

    // 2. Check if confirmed and context is still valid
    if (confirmed == true && context.mounted) {
      // 3. Show deleting indicator
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Deleting team \"${team.name}\"..."), duration: const Duration(seconds: 30)) // Give API time
      );

      try {
        // 4. Call the API's deleteTeam method
        final success = await api.deleteTeam(team.id);

        // 5. Check context again after async operation
        if (!context.mounted) return;

        // 6. Remove deleting indicator
        ScaffoldMessenger.of(context).removeCurrentSnackBar();

        // 7. Handle API result
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Team deleted successfully"))
          );
          // 8. Refresh the list via the Cubit
          adminCubit.loadTeams();
        } else {
          // API returned false (e.g., team not found, permission denied, server error)
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("❌ Failed to delete team \"${team.name}\". Check logs or permissions."))
          );
        }
      } catch (e) {
        // Handle potential exceptions during the API call
        debugPrint("Error during team deletion API call: $e");
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Ensure loading message is removed
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ An error occurred while deleting team: ${e.toString()}"))
        );
      }
    } else {
      // User cancelled the deletion
      debugPrint("Team deletion cancelled by user.");
    }
  }
// --- End Delete Handler ---

}