import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../models/building_model.dart';
import '../../models/faculty_model.dart';
import '../../models/hall_model.dart';
import '../../models/lab_model.dart';
import '../../models/location_model.dart';
import '../../models/search_log_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../navigation/indoor_navigation_setup_screen.dart';
import '../map/offline_maps_screen.dart';
import '../profile/profile_screen.dart';
import '../navigation/outdoor_navigation_screen.dart';
import 'directory_details_screen.dart';

class DirectoryScreen extends StatefulWidget {
  final int initialSegment;
  const DirectoryScreen({super.key, this.initialSegment = 0});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  /// Cache location futures so FutureBuilder doesn't recreate them on rebuild.
  final Map<String, Future<LocationModel?>> _locationFutureCache = {};

  Future<LocationModel?> _getLocationFuture(String locationId) {
    if (locationId.isEmpty) return Future.value(null);
    return _locationFutureCache.putIfAbsent(
      locationId,
      () => _firestoreService.getLocation(locationId),
    );
  }

  // 0: Faculty, 1: Halls, 2: Labs
  int _selectedSegment = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedSegment = widget.initialSegment;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _onNavItemTapped(int index) {
    if (index == 1) return; // already in Directory

    if (index == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // --- Header + Segment Control (scrolls away) ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // --- Header (Back btn + Title) ---
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white, size: 20),
                                onPressed: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  } else {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const HomeScreen()));
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                'Directory',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.065 > 26 ? 26 : MediaQuery.of(context).size.width * 0.065,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- Segmented Control ---
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              _buildSegmentButton(0, 'Faculty'),
                              _buildSegmentButton(1, 'Halls'),
                              _buildSegmentButton(2, 'Labs'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // --- Sticky Search Bar (scrolls up, then pins at top) ---
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _DirectoryStickySearchBarDelegate(
                    child: Container(
                      color: AppColors.backgroundLight,
                      padding: const EdgeInsets.only(
                          bottom: 16.0, left: 24.0, right: 24.0),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 16.0, right: 8.0),
                              child:
                                  Icon(Icons.search, color: Color(0xFF666666)),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: _getSearchHint(),
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Color(0xFF666666), size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // --- List Body ---
                SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildListBody(),
                  ),
                ),
              ],
            ),
          ),

          // Floating Bottom Nav Bar
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: CustomBottomNavBar(
              currentIndex: 1, // Directory is index 1
              onTap: _onNavItemTapped,
            ),
          ),
        ],
      ),
    );
  }

  String _getSearchHint() {
    switch (_selectedSegment) {
      case 0:
        return 'Search Faculty cabins...';
      case 1:
        return 'Search Halls...';
      case 2:
        return 'Search Labs...';
      default:
        return 'Search...';
    }
  }

  Widget _buildSegmentButton(int index, String title) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSegment = index;
            _searchController.clear();
            _searchQuery = '';
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF666666),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListBody() {
    switch (_selectedSegment) {
      case 0:
        return _buildFacultyList();
      case 1:
        return _buildHallsList();
      case 2:
        return _buildLabsList();
      default:
        return const SizedBox();
    }
  }

  Widget _buildFacultyList() {
    return StreamBuilder<List<FacultyModel>>(
      stream: _firestoreService.streamAllFaculties(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.black));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var items = (snapshot.data ?? []).toList();
        if (_searchQuery.isNotEmpty) {
          items = items
              .where((f) =>
                  f.name.toLowerCase().contains(_searchQuery) ||
                  f.department.toLowerCase().contains(_searchQuery))
              .toList();
        }
        
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (items.isEmpty) {
          return const Center(child: Text('No faculty found.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final faculty = items[index];
            return _buildDirectoryCard(
              title: faculty.name,
              subtitle: faculty.role.isNotEmpty ? faculty.role : faculty.designation,
              department: faculty.department,
              locationId: faculty.locationId,
              photoUrl: faculty.photoUrl,
              imageBytes: faculty.imageBytes,
              model: faculty,
            );
          },
        );
      },
    );
  }

  Widget _buildHallsList() {
    return StreamBuilder<List<HallModel>>(
      stream: _firestoreService.streamAllHalls(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.black));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var items = (snapshot.data ?? []).toList();
        if (_searchQuery.isNotEmpty) {
          items = items
              .where((h) => h.name.toLowerCase().contains(_searchQuery))
              .toList();
        }
        
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (items.isEmpty) {
          return const Center(child: Text('No halls found.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final hall = items[index];
            return _buildDirectoryCard(
              title: hall.name,
              subtitle: hall.typeString,
              department: 'General',
              locationId: hall.locationId,
              fallbackIcon: Icons.meeting_room,
              model: hall,
            );
          },
        );
      },
    );
  }

  Widget _buildLabsList() {
    return StreamBuilder<List<LabModel>>(
      stream: _firestoreService.streamAllLabs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.black));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var items = (snapshot.data ?? []).toList();
        if (_searchQuery.isNotEmpty) {
          items = items
              .where((l) =>
                  l.name.toLowerCase().contains(_searchQuery) ||
                  l.department.toLowerCase().contains(_searchQuery))
              .toList();
        }

        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (items.isEmpty) {
          return const Center(child: Text('No labs found.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final lab = items[index];
            return _buildDirectoryCard(
              title: lab.name,
              subtitle: 'Laboratory',
              department: lab.department,
              locationId: lab.locationId,
              fallbackIcon: Icons.science,
              model: lab,
            );
          },
        );
      },
    );
  }

  Widget _buildDirectoryCard({
    required String title,
    required String subtitle,
    required String department,
    required String locationId,
    required dynamic model,
    String? photoUrl,
    Uint8List? imageBytes,
    IconData fallbackIcon = Icons.person,
  }) {
    return FutureBuilder<LocationModel?>(
      future: _getLocationFuture(locationId),
      builder: (context, snapshot) {
        final location = snapshot.data;
        return FutureBuilder<BuildingModel?>(
          future: (location != null && location.buildingId != null)
              ? _firestoreService.getBuilding(location.buildingId!)
              : Future.value(null),
          builder: (context, bSnapshot) {
            final buildingName = bSnapshot.data?.name;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DirectoryDetailsScreen(
                      model: model,
                      location: location,
                      buildingName: buildingName,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B1C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Profile/Room Image
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24, width: 1.5),
                        color: const Color(0xFF333333),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageBytes != null
                            ? Image.memory(imageBytes, fit: BoxFit.cover)
                            : (photoUrl != null && photoUrl.isNotEmpty)
                                ? Image.network(photoUrl, fit: BoxFit.cover)
                                : Icon(fallbackIcon, color: Colors.white38, size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info Row
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: MediaQuery.of(context).size.width * 0.04 > 16 ? 16 : MediaQuery.of(context).size.width * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: const Color(0xFF909090),
                              fontSize: MediaQuery.of(context).size.width * 0.033 > 13 ? 13 : MediaQuery.of(context).size.width * 0.033,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Compact Nav Button
                    GestureDetector(
                      onTap: () => _handleNavigationTap(locationId, context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.near_me, color: Colors.black, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleNavigationTap(String locationId, BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.black)),
      );

      final location = await _firestoreService.getLocation(locationId);
      if (location != null && location.buildingId != null && mounted) {
        final building = await _firestoreService.getBuilding(location.buildingId!);

        // Log search for analytics
        if (building != null) {
          final String platform = kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios');

          await _firestoreService.logSearch(SearchLogModel(
            buildingId: building.id,
            buildingName: building.name,
            platform: platform,
            query: location.name,
            timestamp: DateTime.now(),
          ));
          
          // Add to recent searches
          if (mounted) {
            final auth = context.read<app_auth.AuthProvider>();
            await auth.addRecentSearch(locationId);
            await _firestoreService.incrementSearchCount(locationId);
          }
        }

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          if (building != null && building.entryPoints.isNotEmpty) {
            final entryPoint = building.entryPoints.first;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OutdoorNavigationScreen(
                  targetBuilding: building,
                  targetEntryPoint: entryPoint,
                  destinationId: location.id,
                  destinationName: location.name,
                  destLat: entryPoint.latitude,
                  destLng: entryPoint.longitude,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Building or entry point data not found.')),
            );
          }
        }
      } else {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location data not found.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _DirectoryStickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _DirectoryStickySearchBarDelegate({required this.child});

  @override
  double get minExtent => 66.0;

  @override
  double get maxExtent => 66.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _DirectoryStickySearchBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
