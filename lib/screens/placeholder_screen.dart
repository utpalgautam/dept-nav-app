import 'package:flutter/material.dart';
import 'package:my_app/widgets/app_header.dart';
import 'package:my_app/widgets/app_bottom_nav.dart';
import 'package:my_app/theme/app_theme.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final int activeIndex;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              AppHeader(
                title: title,
                showDivider: false,
              ),
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getIconForIndex(activeIndex),
                        size: 64,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'To be added...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.iosGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomNav(activeIndex: activeIndex),
          ),
        ],
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.home_outlined;
      case 1:
        return Icons.import_contacts_outlined;
      case 2:
        return Icons.search;
      case 3:
        return Icons.cloud_off;
      default:
        return Icons.help_outline;
    }
  }
}
