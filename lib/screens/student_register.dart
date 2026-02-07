import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_field.dart';
import '../widgets/email_field.dart';
import '../widgets/primary_button.dart';
import '../utils/validators.dart';

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  State<StudentRegisterScreen> createState() =>
      _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final nameController = TextEditingController();
  final rollController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool passwordsMatch = false;
  bool hasStartedTypingConfirm = false;

  bool emailTyped = false;
  bool emailValid = false;

  void checkPasswordMatch() {
    setState(() {
      hasStartedTypingConfirm =
          confirmPasswordController.text.isNotEmpty;

      passwordsMatch =
          passwordController.text ==
              confirmPasswordController.text &&
          hasStartedTypingConfirm;
    });
  }

  void checkEmail() {
    setState(() {
      emailTyped = emailController.text.isNotEmpty;
      emailValid = Validators.isValidEmail(emailController.text);
    });
  }

  @override
  void initState() {
    super.initState();
    passwordController.addListener(checkPasswordMatch);
    confirmPasswordController.addListener(checkPasswordMatch);
    emailController.addListener(checkEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(
              label: "Full Name",
              controller: nameController,
            ),
            const SizedBox(height: 12),

            CustomTextField(
              label: "Roll Number",
              controller: rollController,
            ),
            const SizedBox(height: 12),

            EmailField(
              controller: emailController,
              isValid: emailTyped ? emailValid : null,
            ),

            if (emailTyped && !emailValid)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  "Email must end with @nitc.ac.in or @gmail.com",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            const SizedBox(height: 12),

            CustomTextField(
              label: "Password",
              controller: passwordController,
              obscure: true,
            ),
            const SizedBox(height: 12),

            PasswordField(
              controller: confirmPasswordController,
              match: hasStartedTypingConfirm ? passwordsMatch : null,
            ),

            const SizedBox(height: 24),

            PrimaryButton(
              text: "Create Account",
              onPressed: () {
                if (!passwordsMatch || !emailValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please fix errors"),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
