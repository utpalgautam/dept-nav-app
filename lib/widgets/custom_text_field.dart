import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final bool obscure;
  final Widget? suffix;
  final Widget? prefix;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.label,
    this.obscure = false,
    this.suffix,
    this.prefix,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label is now optional or handled outside if needed, 
        // but for this design we might want to hide the top label 
        // if it's not passed, or style it differently.
        // The design shows labels outside the box.
        
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(
            color: Colors.black, 
          ),
          decoration: InputDecoration(
            hintText: label,
            suffixIcon: suffix,
            prefixIcon: prefix,
          ),
        ),
      ],
    );
  }
}
