import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../models/location_model.dart';
import '../../models/faculty_model.dart';
import '../../models/hall_model.dart';
import '../../models/lab_model.dart';
import '../../models/search_log_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../navigation/outdoor_navigation_screen.dart';
import '../directory/directory_details_screen.dart';

class RecentSearchesScreen extends StatefulWidget {
  const RecentSearchesScreen({super.key});

  @override
  State<RecentSearchesScreen> createState() => _RecentSearchesScreenState();
}

class _RecentSearchesScreenState extends State<RecentSearchesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<LocationModel> _recentSearches = [];
  Map<String, String> _buildingNames = {};
  Map<String, dynamic> _locationModels = {};

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<app_auth.AuthProvider>();
      final currentUser = auth.currentUser;
      if (currentUser != null && currentUser.recentSearches.isNotEmpty) {
        // fetching max 8
        final ids = currentUser.recentSearches.take(8).toList();
        final locations = await _firestoreService.getLocationsByIds(ids);
        
        // Ensure they match the order of ids
        final orderedLocs = <LocationModel>[];
        for (final id in ids) {
          final loc = locations.where((l) => l.id == id).firstOrNull;
          if (loc != null) orderedLocs.add(loc);
        }

        // Fetch building names mostly locally if we just know the ID,
        // but let's query the db for the names to be safe.
        final neededBuildingIds = orderedLocs.map((l) => l.buildingId).whereType<String>().toSet();
        final Map<String, String> bNames = {};
        for (final bId in neededBuildingIds) {
          final building = await _firestoreService.getBuilding(bId);
          if (building != null) {
            bNames[bId] = building.name;
          }
        }

        // Fetch specific models for each location
        final Map<String, dynamic> locModels = {};
        for (final loc in orderedLocs) {
          if (loc.type == LocationType.faculty) {
            locModels[loc.id] = await _firestoreService.getFacultyByLocationId(loc.id);
          } else if (loc.type == LocationType.hall) {
            locModels[loc.id] = await _firestoreService.getHallByLocationId(loc.id);
          } else if (loc.type == LocationType.lab) {
            locModels[loc.id] = await _firestoreService.getLabByLocationId(loc.id);
          }
        }

        if (mounted) {
          setState(() {
            _recentSearches = orderedLocs;
            _buildingNames = bNames;
            _locationModels = locModels;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _recentSearches = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
         setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeSearch(String locationId) async {
    final auth = context.read<app_auth.AuthProvider>();
    if (auth.currentUser != null) {
       await auth.removeRecentSearch(locationId);
       setState(() {
         _recentSearches.removeWhere((loc) => loc.id == locationId);
       });
    }
  }

  Future<void> _clearAll() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All'),
        content: const Text('Are you sure you want to clear all recent searches?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final auth = context.read<app_auth.AuthProvider>();
    if (auth.currentUser != null) {
       await auth.clearRecentSearches();
       setState(() {
         _recentSearches.clear();
       });
    }
  }

  Future<void> _navigateToLocation(LocationModel location) async {
    final auth = context.read<app_auth.AuthProvider>();
    if (auth.currentUser != null) {
        await auth.addRecentSearch(location.id);
        await _firestoreService.incrementSearchCount(location.id);
    }
    
    if (!mounted) return;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.black)),
    );

    try {
       if (location.buildingId != null) {
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
          }
          
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            if (building != null && building.entryPoints.isNotEmpty) {
               final entryPoint = building.entryPoints.first; // Default to first entry point
               await Navigator.push(
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
               _loadRecentSearches();
            } else {
               ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Building or entry point data not found.')),
               );
            }
          }
       } else {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Building data not found for this location.')),
          );
       }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        debugPrint('Error initiating navigation: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred while initiating navigation.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // slight off-white like in the design
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // --- Header ---
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 24),
                  const Expanded(
                    child: Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // --- content ---
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : _recentSearches.isEmpty
                        ? const Center(
                            child: Text(
                              'No recent searches.',
                              style: TextStyle(color: Color(0xFF888888), fontSize: 16),
                            ),
                          )
                        : _buildSearchesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchesList() {
    // Split into today and yesterday for the UI mockup
    final List<LocationModel> todaySearches = [];
    final List<LocationModel> yesterdaySearches = [];
    
    for (int i = 0; i < _recentSearches.length; i++) {
        if (i < 3) {
            todaySearches.add(_recentSearches[i]);
        } else {
            yesterdaySearches.add(_recentSearches[i]);
        }
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // TODAY Header
        if (todaySearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TODAY',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: _clearAll,
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...todaySearches.map((loc) => _buildCard(loc)),
        ],

        // YESTERDAY Header
        if (yesterdaySearches.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'YESTERDAY',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...yesterdaySearches.map((loc) => _buildCard(loc)),
        ],
        
        const SizedBox(height: 48), // Bottom padding
      ],
    );
  }

  Widget _buildCard(LocationModel location) {
    // Determine building and floor text
    String buildingName = _buildingNames[location.buildingId] ?? 'Unknown Building';
    if (buildingName.isEmpty) buildingName = 'IT Complex';
    
    final model = _locationModels[location.id];
    String subtitle = location.roomNumber != null ? '${location.roomNumber} - $buildingName' : buildingName;
    
    // If we have a sub-text for different types
    if (model != null) {
      if (model is FacultyModel) {
        subtitle = model.role.isNotEmpty ? model.role : model.designation;
      } else if (model is HallModel) {
        subtitle = model.typeString;
      } else if (model is LabModel) {
        subtitle = 'Laboratory';
      }
    }

    // Icon fallback / Image bytes
    dynamic imageToDisplay;
    IconData fallbackIcon = Icons.location_on;
    
    if (model != null) {
      if (model is FacultyModel) {
        imageToDisplay = model.imageBytes ?? model.photoUrl;
        fallbackIcon = Icons.person;
      } else if (model is HallModel) {
        fallbackIcon = Icons.meeting_room;
      } else if (model is LabModel) {
        fallbackIcon = Icons.science;
      }
    }

    return GestureDetector(
      onTap: () {
        if (model != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DirectoryDetailsScreen(
                model: model,
                location: location,
                buildingName: _buildingNames[location.buildingId],
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1C), // Matching directory card color
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Left Image (matching directory style)
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
                child: imageToDisplay != null
                    ? (imageToDisplay is Uint8List
                        ? Image.memory(imageToDisplay, fit: BoxFit.cover)
                        : Image.network(imageToDisplay as String, fit: BoxFit.cover))
                    : Icon(fallbackIcon, color: Colors.white38, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF909090),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Navigate button
            GestureDetector(
              onTap: () => _navigateToLocation(location),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.near_me, color: Colors.black, size: 18),
              ),
            ),
            const SizedBox(width: 4),
            // Remove button
            GestureDetector(
              onTap: () => _removeSearch(location.id),
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.transparent, 
                child: const Icon(Icons.close, color: Colors.white54, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
