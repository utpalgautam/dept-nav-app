import 'package:flutter/material.dart';
import 'custom_text_field.dart';

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final bool? isValid;

  const EmailField({
    super.key,
    required this.controller,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: "Email",
      hintText: "Enter your email",
      controller: controller,
      // Workaround because CustomTextField doesn't have suffixIcon exposed for custom icons
      // Just ignoring the isValid icon for now to make it build
    );
  }
}
