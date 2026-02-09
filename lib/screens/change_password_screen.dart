import 'package:flutter/material.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/widgets/pressed_effect.dart';
import 'package:my_app/widgets/custom_button.dart';
import 'package:my_app/widgets/app_header.dart';
import 'package:my_app/widgets/app_bottom_nav.dart';

enum FieldStatus { none, match, mismatch }

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  // Validation states
  bool get _hasMinLength => _newController.text.length >= 8;
  bool get _hasUppercase => _newController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _newController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _newController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _newController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  
  bool get _doPasswordsMatch => 
      _newController.text.isNotEmpty && 
      _confirmController.text.isNotEmpty && 
      _newController.text == _confirmController.text;

  bool get _isConfirmFieldFilled => _confirmController.text.isNotEmpty;

  bool get _canUpdate => 
      _currentController.text.isNotEmpty && 
      _hasMinLength && 
      _hasUppercase && 
      _hasLowercase && 
      _hasNumber && 
      _hasSpecial && 
      _doPasswordsMatch;

  @override
  void initState() {
    super.initState();
    _currentController.addListener(() => setState(() {}));
    _newController.addListener(() => setState(() {}));
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color currentTextColor = isDark ? Colors.white : const Color(0xFF181B0E);

    return Scaffold(
      backgroundColor: isDark ? AppColors.brandDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.05 : 0.03,
              child: CustomPaint(
                painter: GridPainter(color: isDark ? Colors.white : Colors.black),
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              AppHeader(
                title: 'Change Password',
                onBack: () => Navigator.pop(context),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        label: 'Current Password',
                        controller: _currentController,
                        isVisible: _currentPasswordVisible,
                        onToggle: () => setState(() => _currentPasswordVisible = !_currentPasswordVisible),
                        textColor: currentTextColor,
                        isDark: isDark,
                        primaryColor: AppColors.primary,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: PressedEffect(
                          onPressed: () {},
                          child: const Padding(
                            padding: EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildPasswordField(
                        label: 'New Password',
                        controller: _newController,
                        isVisible: _newPasswordVisible,
                        onToggle: () => setState(() => _newPasswordVisible = !_newPasswordVisible),
                        textColor: currentTextColor,
                        isDark: isDark,
                        primaryColor: AppColors.primary,
                        showCheck: _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber,
                      ),
                      const SizedBox(height: 12),
                      _buildValidationIndicator('At least 8 characters', _hasMinLength),
                      _buildValidationIndicator('Uppercase & Lowercase letters', _hasUppercase && _hasLowercase),
                      _buildValidationIndicator('Numbers & Special characters', _hasNumber && _hasSpecial),
                      const SizedBox(height: 24),
                      _buildPasswordField(
                        label: 'Confirm New Password',
                        controller: _confirmController,
                        isVisible: _confirmPasswordVisible,
                        onToggle: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                        textColor: currentTextColor,
                        isDark: isDark,
                        primaryColor: AppColors.primary,
                        status: _isConfirmFieldFilled 
                            ? (_doPasswordsMatch ? FieldStatus.match : FieldStatus.mismatch) 
                            : FieldStatus.none,
                      ),
                      const SizedBox(height: 48),
                      CustomButton(
                        label: 'Update Password',
                        onPressed: _canUpdate ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password updated successfully!')),
                          );
                          Navigator.pop(context);
                        } : null,
                        backgroundColor: AppColors.primary,
                        fontSize: 18,
                        height: 56,
                      ),
                      const SizedBox(height: 120), // Spacing for bottom nav
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomNav(activeIndex: 4, isRoot: false),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationIndicator(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isValid ? AppColors.primary : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? AppColors.primary : Colors.grey[500],
              fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggle,
    required Color textColor,
    required bool isDark,
    required Color primaryColor,
    FieldStatus status = FieldStatus.none,
    bool showCheck = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (showCheck) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: status == FieldStatus.mismatch 
                ? Colors.red.withValues(alpha: 0.5) 
                : (status == FieldStatus.match ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent),
              width: 1.5,
            ),
            boxShadow: AppDecorations.softShadow,
          ),
          child: TextField(
            controller: controller,
            obscureText: !isVisible,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: '••••••••',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status == FieldStatus.mismatch)
                    const Icon(Icons.close, color: Colors.red, size: 20),
                  if (status == FieldStatus.match)
                    const Icon(Icons.check, color: AppColors.primary, size: 20),
                  IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: onToggle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
