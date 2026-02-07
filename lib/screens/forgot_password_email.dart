import 'package:flutter/material.dart';

import '../widgets/custom_text_field.dart';
import '../widgets/floating_background.dart';
import '../widgets/primary_button.dart';
import '../widgets/otp_input_field.dart';
import '../utils/validators.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isValidEmail = false;
  bool emailTyped = false;
  bool showOtpSection = false;
  String currentOtp = '';

  @override
  void initState() {
    super.initState();

    emailController.addListener(() {
      final email = emailController.text.trim();
      final valid = Validators.isValidEmail(email);

      setState(() {
        emailTyped = emailController.text.isNotEmpty;
        isValidEmail = valid;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
      ),
      body: FloatingBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter your email to receive a verification code",
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: "Email Address",
                  controller: emailController,
                  suffix: emailTyped
                      ? Icon(
                          isValidEmail ? Icons.check_circle : Icons.cancel,
                          color: isValidEmail ? Colors.green : Colors.red,
                        )
                      : null,
                ),
                if (emailTyped && !isValidEmail)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "Email must end with @nitc.ac.in or @gmail.com",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 30),
                PrimaryButton(
                  text: "Send OTP",
                  onPressed: isValidEmail
                      ? () {
                          setState(() {
                            showOtpSection = true;
                            currentOtp = '';
                          });
                        }
                      : () {},
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: showOtpSection
                      ? Column(
                          children: [
                            const SizedBox(height: 40),
                            Divider(color: textColor?.withValues(alpha: 0.3)),
                            const SizedBox(height: 30),
                            Text(
                              "OTP sent to ${emailController.text}",
                              style: TextStyle(color: textColor),
                            ),
                            const SizedBox(height: 24),
                            OtpInputField(
                              length: 6,
                              onChanged: (otp) {
                                setState(() {
                                  currentOtp = otp;
                                });
                              },
                            ),
                            const SizedBox(height: 30),
                            PrimaryButton(
                              text: "Verify",
                              onPressed: currentOtp.length == 6
                                  ? () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text("OTP verified successfully"),
                                        ),
                                      );
                                      Navigator.popUntil(
                                          context, (route) => route.isFirst);
                                    }
                                  : () {},
                            ),
                          ],
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }
}
