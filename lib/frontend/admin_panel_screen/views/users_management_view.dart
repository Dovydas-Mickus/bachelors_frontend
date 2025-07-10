import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/frontend/admin_panel_screen/cubit/admin_cubit.dart';
import 'package:micki_nas/frontend/home_screen/home_screen.dart';
import 'package:micki_nas/frontend/home_screen/src/files/cubit/files_cubit.dart';
import '../components/add_user_dialog.dart';


class UsersManagementView extends StatelessWidget {
  const UsersManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final adminCubit = context.watch<AdminCubit>();
    final apiRepository = context.read<APIRepository>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Manage Users",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text("Create User"),
                onPressed: () async {
                  // 1. Show AddUserDialog
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) => const AddUserDialog(), // Use the new dialog
                  );

                  // 2. Handle dialog result
                  if (result != null && context.mounted) {
                    // Extract data from the result map
                    final firstName = result['first_name'] as String?;
                    final lastName = result['last_name'] as String?;
                    final email = result['email'] as String?;
                    final password = result['password'] as String?;
                    final role = result['role'] as String?;

                    // Validate extracted data
                    if (firstName == null || lastName == null || email == null || password == null || role == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("❌ Invalid data received from dialog.")),
                      );
                      return;
                    }

                    // Show loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Creating user...")),
                    );

                    // Call apiRepository.registerUser
                    final success = await apiRepository.registerUser(
                      firstName: firstName,
                      lastName: lastName,
                      email: email,
                      password: password,
                      role: role,
                    );

                    // Handle success/failure
                    if (success && context.mounted) {
                      adminCubit.loadUsers(); // Reload user list
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ User created successfully")),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("❌ Failed to create user")),
                        // TODO: Optionally display specific error from API if available
                      );
                    }
                  } else {
                    // User cancelled the dialog
                    debugPrint("Add user dialog cancelled.");
                  }
                },
              )
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: BlocBuilder<AdminCubit, AdminState>(
            buildWhen: (previous, current) => previous.users != current.users || previous.isLoading != current.isLoading,
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.users.isEmpty) {
                return const Center(child: Text("No users found."));
              }
              // TODO: Replace with UsersList widget
              return ListView.builder(
                itemCount: state.users.length,
                itemBuilder: (context, index) {
                  final user = state.users[index];
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text('${user.firstName} ${user.lastName}'),
                    subtitle: Text(user.email),
                    trailing: IconButton(
                      icon: const Icon(Icons.folder_open),
                      tooltip: 'Browse files',
                      onPressed: () {
                        context.read<APIRepository>().userId = state.users[index].id;
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => HomeScreen(
                            userId: user.id,
                          ),
                        ));
                        context.read<FilesCubit>().loadFolder('', userId:  context.read<APIRepository>().userId);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}