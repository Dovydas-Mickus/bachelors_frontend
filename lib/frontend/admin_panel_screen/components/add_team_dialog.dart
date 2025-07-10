import 'package:flutter/material.dart';

import '../../../core/repositories/models/user.dart';

class AddTeamDialog extends StatefulWidget {
  // Use the User model
  final List<User> allUsers;
  final String? initialName;
  // Expect the lead's email
  final String? initialLeadEmail;
  // Expect a list of member emails (excluding the lead)
  final List<String>? initialMemberEmails;
  // Flag to determine dialog behavior
  final bool isEditMode;
  // Optional: Pass teamId if needed for context, though not used directly here yet
  final String? teamId;

  const AddTeamDialog({
    super.key,
    required this.allUsers,
    this.initialName,
    this.initialLeadEmail,
    this.initialMemberEmails,
    this.isEditMode = false, // Default to create mode
    this.teamId,
  });

  @override
  State<AddTeamDialog> createState() => _AddTeamDialogState();
}

class _AddTeamDialogState extends State<AddTeamDialog> {
  late final TextEditingController _nameController;
  // Stores the emails of users currently checked (includes lead initially if editing)
  late final Set<String> _selectedMemberEmailsState;
  // Stores the email of the user selected in the dropdown
  String? _selectedLeadEmailState;

  // Store initial values to calculate changes in edit mode
  late String _initialNameValue;
  late String? _initialLeadEmailValue;
  late Set<String> _initialMemberEmailsValue; // Stores only non-lead members initially

  @override
  void initState() {
    super.initState();

    // Initialize controllers and state variables
    _nameController = TextEditingController(text: widget.initialName ?? "");
    _selectedLeadEmailState = widget.initialLeadEmail;

    // Initialize the set of currently checked emails
    _selectedMemberEmailsState = {
      // Start with initial members provided (these should NOT include the lead)
      ...?widget.initialMemberEmails,
      // If editing, also mark the initial lead as checked initially
      if (widget.isEditMode && widget.initialLeadEmail != null)
        widget.initialLeadEmail!,
    };

    // Store initial state for comparison in _submit (for edit mode)
    _initialNameValue = widget.initialName ?? "";
    _initialLeadEmailValue = widget.initialLeadEmail;
    // Ensure this *only* contains the initial non-lead members
    _initialMemberEmailsValue = {...?widget.initialMemberEmails};

    // --- Validation/Correction ---
    // Ensure the initial lead is actually in the allUsers list
    if (_selectedLeadEmailState != null &&
        !widget.allUsers.any((user) => user.email == _selectedLeadEmailState)) {
      debugPrint(
          "Warning: Initial lead email '$_selectedLeadEmailState' not found in allUsers list. Resetting lead selection.");
      _selectedLeadEmailState = null; // Reset if lead not found
    }
    // Ensure initial members are in the allUsers list
    _selectedMemberEmailsState
        .removeWhere((email) => !widget.allUsers.any((user) => user.email == email));
    _initialMemberEmailsValue
        .removeWhere((email) => !widget.allUsers.any((user) => user.email == email));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final currentName = _nameController.text.trim();
    final currentLeadEmail = _selectedLeadEmailState;

    // Calculate the set of users currently checked *excluding* the selected lead
    final Set<String> currentMemberEmailsSet = _selectedMemberEmailsState.toSet(); // Create copy
    if (currentLeadEmail != null) {
      currentMemberEmailsSet.remove(currentLeadEmail);
    }
    final List<String> currentMemberEmailsList = currentMemberEmailsSet.toList();


    // --- Validation ---
    if (currentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a team name.")),
      );
      return;
    }
    if (currentLeadEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a team lead.")),
      );
      return;
    }
    // Allow zero members (team can just have a lead)
    // if (currentMemberEmailsSet.isEmpty && currentLeadEmail != null && _selectedMemberEmailsState.length <= 1) {
    //   // Only the lead is selected, which is valid
    // } else if (currentMemberEmailsSet.isEmpty && _selectedMemberEmailsState.isNotEmpty) {
    //    // This case shouldn't happen if logic is correct, but good to consider
    // }


    // --- Determine Result based on Mode ---
    Map<String, dynamic> resultData = {};

    if (widget.isEditMode) {
      // --- Edit Mode: Calculate Changes ---
      List<String>? addEmails;
      List<String>? removeEmails;

      // Calculate added members: emails currently selected (excl. lead) that were NOT initial members
      final added = currentMemberEmailsSet.difference(_initialMemberEmailsValue);
      if (added.isNotEmpty) {
        addEmails = added.toList();
      }

      // Calculate removed members: emails that WERE initial members but are NOT currently selected (excl. lead)
      final removed = _initialMemberEmailsValue.difference(currentMemberEmailsSet);
      if (removed.isNotEmpty) {
        removeEmails = removed.toList();
      }

      // Only include fields in the result if they actually changed
      if (currentName != _initialNameValue) {
        resultData['name'] = currentName;
      }
      if (currentLeadEmail != _initialLeadEmailValue) {
        // Ensure lead email is not null before assigning
        resultData['lead'] = currentLeadEmail;
      }
      if (addEmails != null) {
        resultData['add_emails'] = addEmails;
      }
      if (removeEmails != null) {
        resultData['remove_emails'] = removeEmails;
      }

      // If no changes were detected (resultData is empty)
      if (resultData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ℹ️ No changes detected.")),
        );
        // Optionally pop without data, or just let the user cancel
        // Navigator.of(context).pop(); // Pop without data
        return; // Don't pop with empty data
      }

    } else {
      // --- Create Mode: Return current state ---
      resultData = {
        "name": currentName,
        "lead": currentLeadEmail, // API expects 'lead' key
        "emails": currentMemberEmailsList, // API expects 'emails' key for members
      };
    }

    // Pop with the calculated result data
    Navigator.of(context).pop(resultData);
  }

  @override
  Widget build(BuildContext context) {
    // Filter out the currently selected lead from the checkbox list display options
    // This prevents showing the lead as a selectable member checkbox
    // (they are implicitly a member by being the lead)
    final availableUsersForCheckboxes = widget.allUsers
        .where((user) => user.email != _selectedLeadEmailState)
        .toList();

    return AlertDialog(
      title: Text(widget.isEditMode ? "Edit Team" : "Create Team"),
      content: SizedBox(
        // Consider setting a max width for larger screens
        width: MediaQuery.of(context).size.width * 0.8, // Example max width
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Align labels left
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Team Name",
                  border: OutlineInputBorder(), // Add border
                ),
              ),
              const SizedBox(height: 20),

              // --- Lead Selection Dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedLeadEmailState,
                isExpanded: true, // Make dropdown take available width
                decoration: const InputDecoration(
                  labelText: "Select Team Lead",
                  border: OutlineInputBorder(),
                ),
                // Filter users to ensure they have valid emails
                items: widget.allUsers
                    .where((user) => user.email.isNotEmpty)
                    .map((user) {
                  // Use User model fields
                  final email = user.email;
                  final name = "${user.firstName} ${user.lastName}";
                  return DropdownMenuItem(
                    value: email,
                    // Prevent overly long text
                    child: Text(
                      "$name ($email)",
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    // When lead changes, update the lead state
                    _selectedLeadEmailState = value;
                    // Also ensure the new lead is marked as selected in the checkboxes
                    // And remove the old lead from checkbox selection if they were different
                    if (value != null) {
                      _selectedMemberEmailsState.add(value);
                    }
                    // This logic is simplified because the lead is filtered out
                    // from the checkbox list itself below. We just need to track
                    // the selected lead email state.
                  });
                },
                // Add validation if needed
                validator: (value) => value == null ? 'Please select a lead' : null,
              ),

              const SizedBox(height: 20),
              const Text("Select Team Members:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // --- Member Selection Checkboxes ---
              // Use ListView.builder for potentially long lists
              if (availableUsersForCheckboxes.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true, // Important inside SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(), // Disable scrolling within ListView
                  itemCount: availableUsersForCheckboxes.length,
                  itemBuilder: (context, index) {
                    final user = availableUsersForCheckboxes[index];
                    final email = user.email;
                    final name = "${user.firstName} ${user.lastName}";

                    return CheckboxListTile(
                      title: Text(name),
                      subtitle: Text(email),
                      value: _selectedMemberEmailsState.contains(email),
                      controlAffinity: ListTileControlAffinity.leading, // Checkbox on left
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedMemberEmailsState.add(email);
                          } else {
                            _selectedMemberEmailsState.remove(email);
                          }
                        });
                      },
                    );
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _selectedLeadEmailState != null
                        ? "No other users available to select as members."
                        : "Select a lead first to see available members.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Pop without data
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.isEditMode ? "Save Changes" : "Create Team"),
        ),
      ],
    );
  }
}