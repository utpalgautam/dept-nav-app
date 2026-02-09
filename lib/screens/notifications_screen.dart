import 'package:flutter/material.dart';
import 'package:my_app/widgets/app_header.dart';
import 'package:my_app/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          AppHeader(
            title: 'Notifications',
            onBack: () => Navigator.pop(context),
            showDivider: false,
          ),
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'No Notifications Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We\'ll notify you when something important happens.',
                    style: TextStyle(color: AppColors.iosGray),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
