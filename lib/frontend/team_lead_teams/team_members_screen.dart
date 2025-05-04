// lib/frontend/team_members_screen/team_members_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
import 'package:micki_nas/core/repositories/API.dart'; // Import API Repository
import 'package:micki_nas/core/repositories/models/team.dart';
import 'package:micki_nas/core/repositories/models/user.dart';
import 'package:micki_nas/frontend/home_screen/home_screen.dart';
import 'package:micki_nas/frontend/home_screen/src/files/cubit/files_cubit.dart'; // Import FilesCubit

class TeamMembersScreen extends StatelessWidget {
  final Team team;

  const TeamMembersScreen({
    super.key,
    required this.team,
  });

  @override
  Widget build(BuildContext context) {
    // Sort users, putting lead first (adjust based on your model: users/members)
    final List<User> sortedUsers = List.from(team.members); // Use team.users or team.members
    final lead = team.lead;
    if (lead != null) {
      sortedUsers.removeWhere((user) => user.id == lead.id);
      final leadInList = team.members.firstWhere((u) => u.id == lead.id, orElse: () => lead);
      sortedUsers.insert(0, leadInList);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Members: ${team.name}'),
      ),
      body: team.members.isEmpty // Use team.users or team.members
          ? const Center(
        child: Text(
          'This team has no members.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: sortedUsers.length,
        itemBuilder: (context, index) {
          // Get the specific user for this list item
          final user = sortedUsers[index];
          final bool isLead = user.id == team.lead?.id;

          return ListTile(
            leading: Icon(isLead ? Icons.star_border : Icons.person_outline),
            title: Text('${user.firstName} ${user.lastName}'),
            subtitle: Text(user.email),
            trailing: isLead
                ? const Chip( /* ... Lead Chip details ... */
              label: Text('Lead'),
              avatar: Icon(Icons.star, size: 16, color: Colors.orangeAccent),
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              labelPadding: EdgeInsets.only(left: 4),
              visualDensity: VisualDensity.compact,
            )
                : const Icon(Icons.folder_open_outlined, size: 20, color: Colors.grey), // Folder icon instead of arrow

            // --- Implement onTap Handler ---
            onTap: () {
              // 1. Get necessary context/providers
              final apiRepository = context.read<APIRepository>();
              final filesCubit = context.read<FilesCubit>(); // Ensure FilesCubit is provided above this screen

              // 2. Get the ID of the tapped user
              final targetUserId = user.id;

              debugPrint("ListTile tapped for user ID: $targetUserId (${user.email})");

              // 3. Set the userId in the APIRepository (Use with caution - see note below)
              apiRepository.userId = targetUserId;
              debugPrint("Set apiRepository.userId to: ${apiRepository.userId}");


              // 4. Navigate to HomeScreen, passing the target user's ID
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => HomeScreen(
                  // Pass the user ID whose files should be displayed
                  userId: targetUserId,
                  // Optional: Pass name for title customization in HomeScreen
                  // browsingUserName: '${user.firstName} ${user.lastName}',
                ),
              ));

              // 5. Trigger loading the root folder for the target user in FilesCubit
              // Use the ID stored in the repository (or the targetUserId directly)
              filesCubit.loadFolder('', userId: apiRepository.userId);
              debugPrint("Triggered filesCubit.loadFolder for userId: ${apiRepository.userId}");

            }, // End onTap
          );
        },
      ),
    );
  }
}