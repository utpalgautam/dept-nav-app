import 'package:flutter/material.dart';

class GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Image.asset(
        'assets/images/google.png',
        height: 18,
      ),
      label: const Text(
        "Continue with Google",
        style: TextStyle(fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // pill shape
        ),
      ),
    );
  }
}
