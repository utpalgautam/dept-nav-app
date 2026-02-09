import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/widgets/pressed_effect.dart';
import 'package:my_app/widgets/app_bottom_nav.dart';

class SavedSpotsScreen extends StatefulWidget {
  const SavedSpotsScreen({super.key});

  @override
  State<SavedSpotsScreen> createState() => _SavedSpotsScreenState();
}

class _SavedSpotsScreenState extends State<SavedSpotsScreen> {
  final List<Map<String, String>> _savedSpots = [
    {
      'title': 'Dr. Uma Maheshwar',
      'subtitle': 'Room No. MB206',
      'designation': 'Assistant Professor',
      'contact': '+91 98765 43210',
      'email': 'busharma@nitc.ac.in',
      'image': 'https://nitc.ac.in/imgserver/uploads/attachments/pcm__5ff27ba4-f705-418f-a189-9ad4a89a236b_0.png',
    },
    {
      'title': 'Dr. Sourav Biswas',
      'subtitle': 'Room No. MB109',
      'designation': 'Assistant Professor',
      'contact': '+91 98765 43211',
      'email': 'souravbiswas@nitc.ac.in',
      'image': 'https://admin.minerva.nitc.ac.in/uploads/Sourav_Biswas_8abf4d003d.png',
    },
    {
      'title': 'Dr. Shweta',
      'subtitle': 'Room No. MB209',
      'designation': 'Assistant Professor',
      'contact': '+91 98765 43212',
      'email': 'shweta@nitc.ac.in',
      'image': 'https://admin.minerva.nitc.ac.in/uploads/Shweta_3f47db4401.png',
    },
    {
      'title': 'Main Library',
      'subtitle': 'Building A, Floor 2',
      'designation': 'Central Facility',
      'contact': '+91 98765 43200',
      'email': 'library@nitc.ac.in',
      'image': 'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?q=80&w=200&auto=format&fit=crop',
    },
  ];

  void _showDetails(Map<String, String> spot) {
    showDialog(
      context: context,
      builder: (context) => _FacultyDetailsDialog(spot: spot),
    );
  }

  void _removeSpot(int index) {
    setState(() {
      _savedSpots.removeAt(index);
    });
  }

  void _clearLog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
          title: const Text('Clear All Saved Spots?'),
          content: const Text('This action will remove all your saved locations. Are you sure you want to proceed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _savedSpots.clear();
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

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
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
                            'Saved Spots',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : AppColors.brandDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          background: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        '${_savedSpots.length} Locations',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF94A3B8),
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

              // Subheader "Recent Activity" and "Clear Log"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RECENT ACTIVITY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearLog,
                        child: const Text(
                          'Clear Log',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.only(bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final spot = _savedSpots[index];
                      return _SavedSpotItem(
                        title: spot['title']!,
                        subtitle: spot['subtitle']!,
                        isDarkMode: isDarkMode,
                        onDelete: () => _removeSpot(index),
                        onTap: () => _showDetails(spot),
                      );
                    },
                    childCount: _savedSpots.length,
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
}

class _SavedSpotItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDarkMode;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SavedSpotItem({
    required this.title,
    required this.subtitle,
    required this.isDarkMode,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDarkMode ? 0.1 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.delete_outline, color: Color(0xFF94A3B8), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PressedEffect(
                  onPressed: () {}, // Navigation logic would go here
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.near_me, color: AppColors.brandDark, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Navigate',
                          style: TextStyle(
                            color: AppColors.brandDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PressedEffect(
                onPressed: onTap,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FacultyDetailsDialog extends StatelessWidget {
  final Map<String, String> spot;

  const _FacultyDetailsDialog({required this.spot});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : AppColors.brandDark;
    final Color subTextColor = isDarkMode ? const Color(0xFF94A3B8) : Colors.grey[600]!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(spot['image']!),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: subTextColor),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              spot['title']!,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              spot['designation']!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.location_on_outlined, 'Location', spot['subtitle']!, subTextColor, textColor),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.phone_outlined, 'Contact', spot['contact']!, subTextColor, textColor),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.email_outlined, 'Email', spot['email']!, subTextColor, textColor),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.brandDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color labelColor, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: labelColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: labelColor, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 14, color: valueColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
