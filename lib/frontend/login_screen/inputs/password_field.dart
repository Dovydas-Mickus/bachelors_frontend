import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/login_cubit.dart';

class PasswordField extends StatefulWidget {
  final ValueChanged<String>? onFieldSubmitted;
  const PasswordField({super.key, this.onFieldSubmitted});

  @override
  PasswordFieldState createState() => PasswordFieldState();
}

class PasswordFieldState extends State<PasswordField> {
  // Initially hide the password
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      textInputAction: TextInputAction.done, // Show the appropriate keyboard button.
      // Control the password visibility using _obscurePassword
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(15),
        hintText: 'Password',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
        // Add a button to toggle password visibility
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            // Toggle the state when button is pressed
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      onChanged: (value) {
        context.read<LoginCubit>().passwordChanged(value);
      },
      // This callback gets invoked when the user presses the "done" (enter) button.
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}
