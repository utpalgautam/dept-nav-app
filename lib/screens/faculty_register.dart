import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_field.dart';
import '../widgets/email_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/floating_background.dart';
import '../utils/validators.dart';
import '../services/firebase_auth_service.dart';
import 'home_screen.dart';

class FacultyRegisterScreen extends StatefulWidget {
  const FacultyRegisterScreen({super.key});

  @override
  State<FacultyRegisterScreen> createState() => _FacultyRegisterScreenState();
}

class _FacultyRegisterScreenState extends State<FacultyRegisterScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final officeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool passwordsMatch = false;
  bool hasStartedTypingConfirm = false;

  bool emailTyped = false;
  bool emailValid = false;

  void checkPasswordMatch() {
    setState(() {
      hasStartedTypingConfirm = confirmPasswordController.text.isNotEmpty;

      passwordsMatch =
          passwordController.text == confirmPasswordController.text &&
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Faculty Registration",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FloatingBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CustomTextField(
                label: "Full Name",
                controller: nameController,
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
                label: "Office Address",
                controller: officeController,
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
                isLoading: _isLoading,
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (!passwordsMatch || !emailValid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fix errors"),
                            ),
                          );
                          return;
                        }

                        final navigator = Navigator.of(context);

                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          await _authService.signUp(
                            email: emailController.text.trim(),
                            password: passwordController.text,
                            role: 'faculty',
                            additionalData: {
                              'name': nameController.text.trim(),
                              'officeAddress': officeController.text.trim(),
                            },
                          );

                          navigator.pushReplacement(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const HomeScreen(showWelcomeDialog: true),
                            ),
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    e.toString().replaceAll('Exception: ', '')),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
