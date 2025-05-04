import 'package:flutter/material.dart';

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>(); // For form validation
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole; // Store the selected role

  // Define available roles (should match backend expectations)
  final List<String> _availableRoles = ['admin', 'team_lead', 'worker'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    // Validate the form
    if (_formKey.currentState?.validate() ?? false) {
      // If valid, pop with the data
      Navigator.of(context).pop({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text, // Don't trim password
        'role': _selectedRole,
      });
    } else {
      // Optional: Show a message if validation fails, though fields show errors
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Please fix the errors above.")),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create New User"),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8, // Adjust width
        child: Form( // Wrap content in a Form widget
          key: _formKey,
          child: SingleChildScrollView( // Allows scrolling if content overflows
            child: Column(
              mainAxisSize: MainAxisSize.min, // Take minimum vertical space
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: "First Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a first name';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next, // Move focus on Enter/Next
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: "Last Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a last name';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email Address",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an email address';
                    }
                    // Basic email format check (consider a more robust regex)
                    if (!RegExp(r'^.+@.+\..+$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) { // Example minimum length
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  obscureText: true, // Hide password input
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Select Role",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  items: _availableRoles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role), // Display role name
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedRole = value);
                  },
                  validator: (value) => value == null ? 'Please select a role' : null,
                ),
              ],
            ),
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
          child: const Text("Create User"),
        ),
      ],
    );
  }
}