// lib/frontend/home_screen/src/files/components/share_options_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_bloc/flutter_bloc.dart'; // If needing UserCubit/AdminCubit
import 'package:micki_nas/core/repositories/API.dart';
import 'package:micki_nas/core/repositories/models/team.dart';
import 'package:micki_nas/core/repositories/models/user.dart'; // If needed
// Import cubit if needed to get current user role/teams easily
// import 'package:micki_nas/frontend/user_cubit/user_cubit.dart';
// import 'package:micki_nas/frontend/admin_panel_screen/cubit/admin_cubit.dart';

enum ShareType { user, team, public }
enum ShareDuration { never, day, week, month }

class ShareOptionsDialog extends StatefulWidget {
  final String filePath; // Relative path of the file being shared
  final APIRepository apiRepository;

  const ShareOptionsDialog({
    super.key,
    required this.filePath,
    required this.apiRepository,
  });

  @override
  State<ShareOptionsDialog> createState() => _ShareOptionsDialogState();
}

class _ShareOptionsDialogState extends State<ShareOptionsDialog> {
  final _formKey = GlobalKey<FormState>();
  ShareType _selectedShareType = ShareType.user; // Default type
  ShareDuration _selectedDuration = ShareDuration.never; // Default duration
  bool _allowDownload = true;
  bool _isLoadingTeams = false;
  bool _isGeneratingLink = false; // For generate button loader

  String? _targetEmail;
  Team? _selectedTeam; // Store the selected Team object
  List<Team> _availableTeams = []; // Teams for the dropdown

  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fetch teams if 'Team' sharing is possible/default
    if (_selectedShareType == ShareType.team) {
      _fetchTeams();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeams() async {
    if (!mounted) return;
    setState(() => _isLoadingTeams = true);
    try {
      // Decide which teams to fetch:
      // Option 1: All teams (if admin or structure allows)
      final teams = await widget.apiRepository.fetchAssociatedTeams();
      // Option 2: Only teams the current user leads (needs UserCubit/state)
      // final teams = await widget.apiRepository.fetchMyTeams();

      if (mounted) {
        setState(() {
          _availableTeams = teams;
          _isLoadingTeams = false;
          // Reset selected team if it's no longer in the fetched list
          if (_selectedTeam != null && !_availableTeams.any((t) => t.id == _selectedTeam!.id)) {
            _selectedTeam = null;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching teams for share dialog: $e");
      if (mounted) {
        setState(() => _isLoadingTeams = false);
        // Show error message if needed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error loading teams.")),
        );
      }
    }
  }

  int? _getDurationDays() {
    switch (_selectedDuration) {
      case ShareDuration.day: return 1;
      case ShareDuration.week: return 7;
      case ShareDuration.month: return 30;
      case ShareDuration.never: return null; // No expiry
    }
  }

  void _generateLink() {
    if (_isGeneratingLink) return; // Prevent double taps

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Trigger onSaved for fields

      // Prepare data based on selected type
      String shareTypeStr = _selectedShareType.name; // 'user', 'team', 'public'
      String? email = (shareTypeStr == 'user') ? _targetEmail : null;
      String? teamId = (shareTypeStr == 'team') ? _selectedTeam?.id : null;

      // --- Perform final validation ---
      if (shareTypeStr == 'user' && (email == null || email.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a target email.")),
        );
        return;
      }
      if (shareTypeStr == 'team' && teamId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a target team.")),
        );
        return;
      }

      final shareParams = {
        'shareType': shareTypeStr,
        'targetEmail': email,
        'targetTeamId': teamId,
        'durationDays': _getDurationDays(),
        'allowDownload': _allowDownload,
      };

      debugPrint("Dialog validated. Returning params: $shareParams");
      Navigator.of(context).pop(shareParams); // Return the parameters
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Options'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView( // Make content scrollable
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Share Type Selection ---
              const Text('Share with:', style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<ShareType>(
                title: const Text('Specific User (via Email)'),
                value: ShareType.user,
                groupValue: _selectedShareType,
                onChanged: (ShareType? value) {
                  if (value != null) {
                    setState(() => _selectedShareType = value);
                  }
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<ShareType>(
                title: const Text('Team'),
                value: ShareType.team,
                groupValue: _selectedShareType,
                onChanged: (ShareType? value) {
                  if (value != null) {
                    setState(() => _selectedShareType = value);
                    // Fetch teams only when Team type is selected
                    if (_availableTeams.isEmpty && !_isLoadingTeams) {
                      _fetchTeams();
                    }
                  }
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<ShareType>(
                title: const Text('Anyone with the link (Public)'),
                value: ShareType.public,
                groupValue: _selectedShareType,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (ShareType? value) {
                  if (value != null) {
                    setState(() => _selectedShareType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // --- Conditional Inputs ---
              if (_selectedShareType == ShareType.user)
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: 'Recipient Email',
                      hintText: 'Enter email address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined)
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (_selectedShareType == ShareType.user) { // Only validate if user type is selected
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an email';
                      }
                      // Basic email format check
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                    }
                    return null;
                  },
                  onSaved: (value) => _targetEmail = value?.trim(),
                ),

              if (_selectedShareType == ShareType.team)
                _isLoadingTeams
                    ? const Center(child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ))
                    : DropdownButtonFormField<Team>(
                  value: _selectedTeam,
                  hint: const Text('Select Team'),
                  isExpanded: true,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group_outlined)
                  ),
                  items: _availableTeams.map((Team team) {
                    return DropdownMenuItem<Team>(
                      value: team,
                      child: Text(team.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (Team? newValue) {
                    setState(() {
                      _selectedTeam = newValue;
                    });
                  },
                  validator: (value) {
                    if (_selectedShareType == ShareType.team && value == null) {
                      return 'Please select a team';
                    }
                    return null;
                  },
                  onSaved: (value) { // No need for onSaved if using _selectedTeam directly
                    // _targetTeamId = value?.id; // Set if needed, but _selectedTeam is available
                  },
                ),

              const SizedBox(height: 20),

              // --- Duration ---
              const Text('Link Expiry:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<ShareDuration>(
                value: _selectedDuration,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timer_outlined)
                ),
                items: const [
                  DropdownMenuItem(value: ShareDuration.never, child: Text('Never Expires')),
                  DropdownMenuItem(value: ShareDuration.day, child: Text('1 Day')),
                  DropdownMenuItem(value: ShareDuration.week, child: Text('7 Days')),
                  DropdownMenuItem(value: ShareDuration.month, child: Text('30 Days')),
                ],
                onChanged: (ShareDuration? value) {
                  if (value != null) {
                    setState(() => _selectedDuration = value);
                  }
                },
              ),
              const SizedBox(height: 10),

              // --- Allow Download ---
              SwitchListTile(
                title: const Text('Allow Download'),
                value: _allowDownload,
                onChanged: (bool value) {
                  setState(() {
                    _allowDownload = value;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
                secondary: Icon(_allowDownload ? Icons.download_done_outlined : Icons.download),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(), // Return null
        ),
        ElevatedButton.icon(
          icon: _isGeneratingLink
              ? Container(
              width: 18, height: 18,
              padding: const EdgeInsets.all(2.0),
              child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
          )
              : const Icon(Icons.link),
          label: Text(_isGeneratingLink ? 'Generating...' : 'Generate Link'),
          onPressed: _isGeneratingLink ? null : _generateLink,
        ),
      ],
    );
  }
}

// Helper Dialog to show the generated link
Future<void> showShareLinkDialog(BuildContext context, String shareUrl) {
  final controller = TextEditingController(text: shareUrl);
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Share Link Generated'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              const Text('Copy the link below:'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                readOnly: true,
                maxLines: null, // Allow wrapping
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy_all_outlined),
                      tooltip: 'Copy Link',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: shareUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied to clipboard!'))
                        );
                      },
                    )
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}