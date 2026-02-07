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
      controller: controller,
      suffix: isValid == null
          ? null
          : Icon(
              isValid! ? Icons.check_circle : Icons.cancel,
              color: isValid! ? Colors.green : Colors.red,
            ),
    );
  }
}
