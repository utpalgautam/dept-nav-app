import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/widgets/pressed_effect.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool showDivider;

  const AppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : AppColors.brandDark;
    final Color bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return SliverAppBar(
      pinned: true,
      backgroundColor: bgColor.withValues(alpha: 0.8),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: onBack != null
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: PressedEffect(
                onPressed: onBack,
                child: Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
                ),
              ),
            )
          : null,
      centerTitle: true,
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: actions ?? [const SizedBox(width: 56)],
      bottom: showDivider
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: isDark ? const Color(0xFF27272A) : AppColors.iosDivider,
                height: 1,
              ),
            )
          : null,
    );
  }
}
