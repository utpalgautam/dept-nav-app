import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../profile/profile_screen.dart';
import 'search_screen.dart';
import '../navigation/indoor_navigation_setup_screen.dart';
import '../directory/directory_screen.dart';
import '../map/offline_maps_screen.dart';
import '../map/explore_map_screen.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/animated_rainbow_border.dart';
import '../../main.dart' show AuthWrapper;
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _onNavItemTapped(int index) {
    if (index == 0) return;
    if (index == 1) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DirectoryScreen()));
    } else if (index == 2) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const IndoorNavigationSetupScreen()));
    } else if (index == 3) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const OfflineMapsScreen()));
    } else if (index == 4) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<app_auth.AuthProvider>().currentUser;
    final String firstName = user?.name.split(' ').first ?? 'User';
    final String? profileImageUrl = user?.profileImageUrl;

    final double screenHeight = MediaQuery.of(context).size.height;
    // Hero fills ~45 % of screen
    final double heroHeight = screenHeight * 0.5;
    // White card overlaps image by this amount
    const double cardOverlap = 48.0;
    // Search bar dimensions
    const double searchH = 54.0;
    // Search bar floats so its centre aligns with the image/card boundary
    final double searchTop = heroHeight - cardOverlap - searchH - 6;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenHeight = constraints.maxHeight;
          final double screenWidth = constraints.maxWidth;
          
          // Nudged slightly to prevent overflow on very small devices
          final double heroHeight = screenHeight < 680 ? screenHeight * 0.40 : screenHeight * 0.48;
          
          // White card overlaps image
          const double cardOverlap = 23.0;
          
          // Search bar dimensions
          const double searchH = 54.0;
          
          // Search bar floats entirely above the boundary
          // Nudge up or down based on screen height
          final double searchTop = heroHeight - cardOverlap - searchH - (screenHeight < 700 ? 8 : 14);

          return Stack(
            children: [
              // ── 1. Hero image ──────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: heroHeight,
                child: _buildHeroImage(context, firstName, profileImageUrl),
              ),

              // ── 2. Content Card ────────────────────────────────────────
              Positioned(
                top: heroHeight - cardOverlap,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 10,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, screenHeight < 700 ? 10 : 20, 20, 95), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildMapCard(screenHeight),
                        SizedBox(height: screenHeight < 700 ? 12 : 18),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
              ),

              // ── 3. Search Bar ──────────────────────────────────────────
              Positioned(
                top: searchTop,
                left: 20,
                right: 20,
                height: searchH,
                child: _buildSearchBar(),
              ),

              // ── 4. Fixed Nav Bar ───────────────────────────────────────
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 10,
                left: 24,
                right: 24,
                child: CustomBottomNavBar(
                  currentIndex: 0,
                  onTap: _onNavItemTapped,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Hero image with greeting + avatar ────────────────────────────────────
  Widget _buildHeroImage(BuildContext context, String firstName, String? profileImageUrl) {
    final auth = context.watch<app_auth.AuthProvider>();
    final isGuest = auth.isGuest;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'lib/screens/home/image 36.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFFDDDDDD)),
        ),
        // Light gradient at top for readability
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0x33000000), Colors.transparent],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGuest ? 'Welcome,' : 'Welcome back,',
                      style: TextStyle(
                        color: const Color(0xFF555555),
                        fontSize: screenHeight < 700 ? 14 : 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGuest ? 'Hello User!' : 'Hello, $firstName!',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: screenHeight < 700 ? 24 : 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
                if (!isGuest)
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.pastelOrange,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        image: _getAvatarImage(profileImageUrl),
                      ),
                      child: profileImageUrl == null || profileImageUrl.isEmpty
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 28)
                          : null,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      auth.setGuestMode(false);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthWrapper(hasSeenOnboarding: true)),
                        (route) => false,
                      );
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.black12, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.logout,
                          color: Colors.black, size: 24),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Returns a DecorationImage for the avatar, handling base64 data URIs.
  DecorationImage? _getAvatarImage(String? profileImageUrl) {
    if (profileImageUrl == null || profileImageUrl.isEmpty) return null;

    ImageProvider provider;
    if (profileImageUrl.startsWith('data:image')) {
      try {
        final base64Str = profileImageUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        provider = MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    } else {
      provider = NetworkImage(profileImageUrl);
    }

    return DecorationImage(image: provider, fit: BoxFit.cover);
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const SearchScreen())),
      child: AnimatedRainbowBorder(
        borderRadius: 30,
        borderWidth: 2,
        backgroundColor: Colors.white,
        child: Container(
          height: 50, // Controlled by AnimatedRainbowBorder's child container
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.black54, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search cabins, halls, labs...',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapCard(double screenHeight) {
    // Dynamic map card height: shrink more on very small screens
    double cardH;
    if (screenHeight < 650) {
      cardH = 120; // Even smaller
    } else if (screenHeight < 750) {
      cardH = 140;
    } else {
      cardH = 175;
    }
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ExploreMapScreen())),
      child: Container(
        width: double.infinity,
        height: cardH,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(36),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -55,
              top: -55,
              child: Container(
                width: 210,
                height: 210,
                decoration: const BoxDecoration(
                  color: AppColors.accentDark,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 24,
              top: -40,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C2C2C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.map_outlined,
                      color: Colors.white, size: 30),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Intractive',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                  const Spacer(),
                  const Text('Explore NITC Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      )),
                  const SizedBox(height: 6),
                  const Text(
                    'Find your way around campus locations.\ninstantly.',
                    style: TextStyle(
                        color: Color(0xFFAAAAAA), fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick action',
            style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        // Use Wrap for better responsiveness on small/narrow screens
        // Row for balanced spacing between items
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1 – Search
            _buildActionItem(
              icon: Icons.search,
              label: 'Search',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SearchScreen())),
            ),
            // 2 – Labs
            _buildActionItem(
              icon: Icons.science_outlined,
              label: 'Labs',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const DirectoryScreen(initialSegment: 2))),
            ),
            // 3 – Buildings
            _buildActionItem(
              icon: Icons.apartment_outlined,
              label: 'Buildings',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OfflineMapsScreen())),
            ),
            // 4 – Faculty
            _buildActionItem(
              icon: Icons.person_outline,
              label: 'Faculty',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const DirectoryScreen(initialSegment: 0))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    // Scale icons based on screen width/height
    final bool isSmall = MediaQuery.of(context).size.height < 700;
    final double iconSize = isSmall ? 44 : 56;
    
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: const Color(0xFFB8C8E8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF4A4A4A), size: isSmall ? 22 : 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: isSmall ? 11 : 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
