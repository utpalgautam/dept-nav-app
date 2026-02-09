import 'package:flutter/material.dart';
import 'package:my_app/widgets/pressed_effect.dart';
import 'package:my_app/theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final bool hasShadow;

  const CustomButton({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.onPressed,
    this.height = 48,
    this.fontSize = 14,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final txtColor = textColor ?? AppColors.brandDark;

    return PressedEffect(
      onPressed: onPressed,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onPressed == null ? Colors.grey[400] : bgColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
          boxShadow: hasShadow && onPressed != null
              ? [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: txtColor,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
