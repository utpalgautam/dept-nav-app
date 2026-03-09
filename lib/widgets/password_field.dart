import 'package:flutter/material.dart';
import 'custom_text_field.dart';

class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool? match;

  const PasswordField({
    super.key,
    required this.controller,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: "Confirm Password",
      hintText: "Confirm your password",
      isPassword: true,
      controller: controller,
    );
  }
}
