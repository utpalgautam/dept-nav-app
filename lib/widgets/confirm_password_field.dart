import 'package:flutter/material.dart';

class ConfirmPasswordField extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmController;

  const ConfirmPasswordField({
    super.key,
    required this.passwordController,
    required this.confirmController,
  });

  @override
  Widget build(BuildContext context) {
    bool match = passwordController.text == confirmController.text &&
        confirmController.text.isNotEmpty;

    return TextField(
      controller: confirmController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: "Confirm Password",
        suffixIcon: Icon(
          match ? Icons.check_circle : Icons.cancel,
          color: match ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
