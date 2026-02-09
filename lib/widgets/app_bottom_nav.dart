import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/widgets/pressed_effect.dart';
import 'package:my_app/screens/placeholder_screen.dart';
import 'package:my_app/screens/profile_screen.dart';

class AppBottomNav extends StatelessWidget {
  final int activeIndex;
  final Function(int)? onTap;
  final bool isTranslucent;
  final bool isRoot;

  const AppBottomNav({
    super.key,
    required this.activeIndex,
    this.onTap,
    this.isTranslucent = true,
    this.isRoot = true,
  });

  void _navigateTo(BuildContext context, int index) {
    if (index == activeIndex && isRoot) return;
    
    if (onTap != null) {
      onTap!(index);
      return;
    }

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const PlaceholderScreen(title: 'Home', activeIndex: 0);
        break;
      case 1:
        nextScreen = const PlaceholderScreen(title: 'Directory', activeIndex: 1);
        break;
      case 2:
        nextScreen = const PlaceholderScreen(title: 'Search', activeIndex: 2);
        break;
      case 3:
        nextScreen = const PlaceholderScreen(title: 'Offline', activeIndex: 3);
        break;
      case 4:
        nextScreen = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF09090B) : Colors.white;
    
    Widget content = Container(
      height: 90,
      padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
      decoration: BoxDecoration(
        color: isTranslucent ? navBg.withValues(alpha: 0.9) : navBg,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF27272A) : AppColors.iosDivider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home_outlined, Icons.home, 'Home', 0, isDark),
          _buildNavItem(context, Icons.import_contacts_outlined, Icons.import_contacts, 'Directory', 1, isDark),
          _buildNavItem(context, Icons.search, Icons.search, 'Search', 2, isDark),
          _buildNavItem(context, Icons.cloud_off, Icons.cloud_off, 'Offline', 3, isDark),
          _buildNavItem(context, Icons.account_circle_outlined, Icons.account_circle, 'Profile', 4, isDark),
        ],
      ),
    );

    if (isTranslucent) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildNavItem(BuildContext context, IconData icon, IconData activeIcon, String label, int index, bool isDark) {
    final bool isActive = activeIndex == index;
    final Color color = isActive ? AppColors.primary : Colors.grey;
    
    return Expanded(
      child: PressedEffect(
        onPressed: () => _navigateTo(context, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
