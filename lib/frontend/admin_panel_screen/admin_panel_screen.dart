import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/frontend/admin_panel_screen/cubit/admin_cubit.dart';
import 'package:micki_nas/frontend/admin_panel_screen/views/audit_log_view.dart';

// Import the separate view widgets we will create
import 'views/teams_management_view.dart';
import 'views/users_management_view.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin { // Needed for TabController animation
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize TabController with 2 tabs (Teams, Users)
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose controller to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provide the AdminCubit once at the top level of this screen
    return BlocProvider(
      create: (context) {
        final cubit = AdminCubit(api: context.read<APIRepository>());
        // Load initial data for BOTH tabs when the cubit is created
        Future.microtask(() {
          cubit.loadTeams();
          cubit.loadUsers(); // Add loadUsers to your Cubit
        });
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          // Add the TabBar to the AppBar's bottom
          bottom: TabBar(
            controller: _tabController, // Make sure _tabController is initialized
            tabs: const [
              Tab(icon: Icon(Icons.group), text: "Teams"),
              Tab(icon: Icon(Icons.person), text: "Users"),
            ],
          ),
          // Add the actions property for buttons on the right side
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.history), // Icon for audit log (history)
              tooltip: 'View Audit Log',       // Tooltip for accessibility
              onPressed: () {
                // Navigate to the AuditLogScreen when pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuditLogScreen()),
                  // If AuditLogScreen needs APIRepository passed via constructor:
                  // MaterialPageRoute(builder: (context) => AuditLogScreen(apiRepository: yourRepoInstance)),
                );
              },
            ),
            // You can add more IconButtons here if needed
            // IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          ],
        ),
        // Use TabBarView in the body to display content based on selected tab
        body: TabBarView(
          controller: _tabController,
          children: const [
            // Content for the first tab (Teams)
            TeamsManagementView(), // We'll create this widget

            // Content for the second tab (Users)
            UsersManagementView(), // We'll create this widget
          ],
        ),
      ),
    );
  }
}