import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micki_nas/frontend/admin_panel_screen/admin_panel_screen.dart';
import 'package:micki_nas/frontend/home_screen/src/right_side_bar/src/logout_button.dart';
import 'package:micki_nas/frontend/home_screen/src/right_side_bar/src/theme_toggle_button.dart';
import 'package:micki_nas/frontend/team_lead_teams/team_lead_teams_screen.dart';
// Import the specific state classes if using the separate state approach
import 'package:micki_nas/frontend/user_cubit/user_cubit.dart';

class RightSideBar extends StatelessWidget {
  const RightSideBar({super.key});

  @override
  Widget build(BuildContext context) {
    // REMOVE this line:
    // final user = context.watch<UserCubit>().state;

    // Use BlocBuilder to listen and get the state
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) { // Use the 'state' variable provided here
        // 'state' is the current UserState object

        // Conditionally build UI based on the state
        return Column(
          children: [
            const SizedBox(height: 40),
            SizedBox(width: 150, child: const ThemeToggleButton()),
            const SizedBox(height: 10),

            // --- Check state type or properties ---
            // Option A: Check properties of the single UserState
            if (state.isLoaded && !state.isLoading) ...[ // Check if loaded and not currently loading
              if (state.role == 'admin') ...[ // Use state.role
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => AdminPanelScreen())); // Use const if possible
                    },
                    child: const Text("Admin Panel"),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (state.role == 'admin' || state.role == 'team_lead') ...[ // Use state.role
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TeamLeadTeamsScreen())); // Use const if possible
                    },
                    child: const Text("Teams Panel"),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // Show logout only when loaded/logged in
              SizedBox(width: 150, child: const LogoutButton()),
            ]
            else if (state.isLoading) ...[
              // Show a loading indicator if desired while profile reloads
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3)),
              ),
            ]
            // Add handling for initial/error states if needed
            // else if (state.errorMessage != null) ... [ Text("Error: ${state.errorMessage}") ]

            // Option B: Check state type (if using separate state classes)
            /*
            if (state is UserLoaded) ...[
              if (state.user.role == 'admin') ...[ ... ],
              if (state.user.role == 'admin' || state.user.role == 'team_lead') ...[ ... ],
              SizedBox(width: 150, child: const LogoutButton()),
            ] else if (state is UserLoading) ... [
              const CircularProgressIndicator(),
            ]
            */

          ],
        );
      },
    );
  }
}