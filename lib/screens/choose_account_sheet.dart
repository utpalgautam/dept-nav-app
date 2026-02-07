import 'package:flutter/material.dart';
import 'student_register.dart';
import 'faculty_register.dart';

void showChooseAccountSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const ChooseAccountSheet(),
  );
}

class ChooseAccountSheet extends StatelessWidget {
  const ChooseAccountSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Choose Account Type",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          ListTile(
            leading: const Icon(Icons.school),
            title: const Text("Student"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentRegisterScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.work),
            title: const Text("Faculty"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FacultyRegisterScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
