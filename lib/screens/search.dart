import 'package:flutter/material.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/widgets/pressed_effect.dart';
import 'package:my_app/widgets/app_bottom_nav.dart';
import 'dart:ui';

class SearchHistoryScreen extends StatefulWidget {
  const SearchHistoryScreen({super.key});

  @override
  State<SearchHistoryScreen> createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends State<SearchHistoryScreen> {
  final List<Map<String, String>> _historyItems = [
    {'title': "Prof. Smith's Cabin", 'subtitle': "Science Building, 3rd Floor"},
    {'title': "Auditorium", 'subtitle': "Main Arts Complex"},
    {'title': "Main Library - 2nd Floor", 'subtitle': "West Wing Study Area"},
    {'title': "Cafeteria Block B", 'subtitle': "Near South Entrance"},
    {'title': "International Office", 'subtitle': "Admin Tower, 1st Floor"},
    {'title': "Gymnasium", 'subtitle': "Sports Center"},
  ];

  void _removeItem(int index) {
    setState(() {
      _historyItems.removeAt(index);
    });
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
          title: const Text('Clear Search History?'),
          content: const Text('This action will remove all your recent search activity. Are you sure you want to proceed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _historyItems.clear();
                });
                Navigator.pop(context);
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF181B0E);
    final Color borderColor = isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Fixed Header from HTML
              SliverAppBar(
                pinned: true,
                backgroundColor: bgColor.withValues(alpha: 0.8),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                expandedHeight: 180,
                collapsedHeight: 64,
                centerTitle: true,
                title: null,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: PressedEffect(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 16, color: isDarkMode ? Colors.white : AppColors.brandDark),
                    ),
                  ),
                ),
                actions: const [
                  SizedBox(width: 56), // Balance the back button for centering
                ],
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final double top = constraints.biggest.height;
                    final double expandedHeight = 180.0;
                    final double collapsedHeight = Scaffold.of(context).appBarMaxHeight ?? 64.0;
                    
                    // Ratio: 1.0 when expanded, 0.0 when collapsed
                    final double ratio = ((top - collapsedHeight) / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);
                    
                    // Interpolate left padding: 24 when expanded, 64 when collapsed
                    final double leftPadding = 64.0 - (40.0 * ratio);
                    
                    return Stack(
                      children: [
                        FlexibleSpaceBar(
                          centerTitle: false,
                          titlePadding: EdgeInsets.only(left: leftPadding, bottom: 35),
                          title: Text(
                            'Search History',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          background: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: GestureDetector(
                                        onTap: _clearAll,
                                        child: const Text(
                                          'Clear All',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          expandedTitleScale: 1.4,
                        ),
                        // Centered EXPLOREE branding that fades out
                        Positioned(
                          top: 10, // Moved lower
                          left: 0,
                          right: 0,
                          height: collapsedHeight,
                          child: Opacity(
                            opacity: (ratio * 2 - 1.0).clamp(0.0, 1.0), // Fades out faster earlier
                            child: Center(
                              child: Text(
                                'EXPLOREE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                  color: (isDarkMode ? Colors.white : AppColors.brandDark).withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(0),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _historyItems[index];
                      return _HistoryListItem(
                        title: item['title']!,
                        subtitle: item['subtitle']!,
                        textColor: textColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                        onRemove: () => _removeItem(index),
                      );
                    },
                    childCount: _historyItems.length,
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomNav(activeIndex: 4, isRoot: false), // Set to Profile tab as this is part of Profile features
          ),
        ],
      ),
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color textColor;
  final Color borderColor;
  final bool isDarkMode;
  final VoidCallback onRemove;

  const _HistoryListItem({
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.borderColor,
    required this.isDarkMode,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return PressedEffect(
      onPressed: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: borderColor),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF0F3E8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.history, color: isDarkMode ? Colors.white : const Color(0xFF181B0E), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            PressedEffect(
              onPressed: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.close, color: Colors.grey[400], size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
