import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../../models/faculty_model.dart';
import '../../models/hall_model.dart';
import '../../models/lab_model.dart';
import '../../models/location_model.dart';
import '../../models/search_log_model.dart';
import '../../services/firestore_service.dart';
import '../navigation/outdoor_navigation_screen.dart';

class DirectoryDetailsScreen extends StatefulWidget {
  final dynamic model; // FacultyModel, LabModel, or HallModel
  final LocationModel? location;
  final String? buildingName;

  const DirectoryDetailsScreen({
    super.key,
    required this.model,
    this.location,
    this.buildingName,
  });

  @override
  State<DirectoryDetailsScreen> createState() => _DirectoryDetailsScreenState();
}

class _DirectoryDetailsScreenState extends State<DirectoryDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  LocationModel? _location;
  String? _buildingName;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _location = widget.location;
    _buildingName = widget.buildingName;
    _fetchLocationDetails();
  }

  Future<void> _fetchLocationDetails() async {
    String? locId;
    if (widget.model is FacultyModel) locId = (widget.model as FacultyModel).locationId;
    else if (widget.model is LabModel) locId = (widget.model as LabModel).locationId;
    else if (widget.model is HallModel) locId = (widget.model as HallModel).locationId;

    if (locId == null || locId.isEmpty) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    try {
      final loc = await _firestoreService.getLocation(locId);
      if (loc != null && mounted) {
        String? bName;
        if (loc.buildingId != null) {
          final b = await _firestoreService.getBuilding(loc.buildingId!);
          bName = b?.name;
        }
        setState(() {
          _location = loc;
          _buildingName = bName;
          _isLoadingLocation = false;
        });
      } else {
        setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      debugPrint('Error fetching location details: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  String get _name {
    if (widget.model is FacultyModel) return (widget.model as FacultyModel).name;
    if (widget.model is LabModel) return (widget.model as LabModel).name;
    if (widget.model is HallModel) return (widget.model as HallModel).name;
    return 'Unknown';
  }

  String get _subtitle {
    if (widget.model is FacultyModel) return (widget.model as FacultyModel).role;
    if (widget.model is LabModel) return 'Laboratory';
    if (widget.model is HallModel) return (widget.model as HallModel).typeString;
    return '';
  }

  String get _department {
    if (widget.model is FacultyModel) return (widget.model as FacultyModel).department;
    if (widget.model is LabModel) return (widget.model as LabModel).department;
    if (widget.model is HallModel) return (widget.model as HallModel).department;
    return 'N/A';
  }

  String get _email {
    if (widget.model is FacultyModel) return (widget.model as FacultyModel).email;
    if (widget.model is LabModel) return (widget.model as LabModel).inchargeEmail ?? 'N/A';
    return 'N/A';
  }

  String get _imageTitle {
    if (widget.model is FacultyModel) return 'Faculty Profile';
    if (widget.model is LabModel) return 'Lab Details';
    if (widget.model is HallModel) return 'Hall Details';
    return 'Details';
  }

  Uint8List? get _imageBytes {
    if (widget.model is FacultyModel) return (widget.model as FacultyModel).imageBytes;
    return null;
  }

  String? get _photoUrl {
    if (widget.model is FacultyModel) return (widget.model as FacultyModel).photoUrl;
    return null;
  }

  IconData get _fallbackIcon {
    if (widget.model is FacultyModel) return Icons.person;
    if (widget.model is LabModel) return Icons.science;
    return Icons.meeting_room;
  }

  Future<void> _handleNavigationTap() async {
    final locationId = _location?.id;
    if (locationId == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.black)),
      );

      final location = await _firestoreService.getLocation(locationId);
      if (location != null && location.buildingId != null && mounted) {
        final building = await _firestoreService.getBuilding(location.buildingId!);

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
          Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Scaling factors based on a "standard" device size
    final hScale = (screenHeight / 812).clamp(0.7, 1.2);
    final wScale = (screenWidth / 375).clamp(0.8, 1.2);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            
            // Adjust sizes based on available height to prevent overflow
            final imageSize = availableHeight < 600 ? 110.0 : (160.0 * hScale);
            final headerFontSize = 24.0 * wScale; // reduced from 26
            final nameFontSize = 24.0 * wScale; // reduced from 28
            final subtitleFontSize = 14.0 * wScale; // reduced from 16
            final spacingHeight = availableHeight < 650 ? 12.0 : 24.0;
            final capsulePadding = availableHeight < 600 ? 10.0 : 16.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(height: availableHeight < 600 ? 10 : 20),
                  // --- Header ---
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _imageTitle,
                          style: TextStyle(
                            fontSize: headerFontSize > 22 ? 22 : headerFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(flex: 1),

                  // --- Image Area ---
                  Center(
                    child: Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(imageSize * 0.28),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            spreadRadius: 10,
                          )
                        ],
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(imageSize * 0.25),
                        child: _imageBytes != null
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                            : (_photoUrl != null && _photoUrl!.isNotEmpty)
                                ? Image.network(_photoUrl!, fit: BoxFit.cover)
                                : Icon(_fallbackIcon, size: imageSize * 0.44, color: Colors.grey[300]),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: spacingHeight),

                  // --- Name & Subtitle ---
                  Text(
                    _name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: nameFontSize > 24 ? 24 : nameFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    style: TextStyle(
                      fontSize: subtitleFontSize > 14 ? 14 : subtitleFontSize,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const Spacer(flex: 1),

                  // --- Info Capsules ---
                  _buildInfoCapsule('Department', _department, capsulePadding),
                  SizedBox(height: availableHeight < 650 ? 8 : 12),
                  
                  // Conditional Lab Incharge
                  if (widget.model is LabModel) ...[
                    _buildInfoCapsule('Lab Incharge', (widget.model as LabModel).incharge ?? 'N/A', capsulePadding),
                    SizedBox(height: availableHeight < 650 ? 8 : 12),
                  ],

                  // Conditional Email (Hidden for Halls)
                  if (widget.model is! HallModel) ...[
                    _buildInfoCapsule('Incharge Email', _email, capsulePadding),
                    SizedBox(height: availableHeight < 650 ? 8 : 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildInfoCapsule(
                          'Cabin',
                          _location?.roomNumber ?? (_isLoadingLocation ? '...' : 'N/A'),
                          capsulePadding,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildInfoCapsule(
                          'Floor',
                          _location?.floor != null ? '${_location!.floor}' : (_isLoadingLocation ? '...' : 'N/A'),
                          capsulePadding,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: availableHeight < 650 ? 8 : 12),
                  _buildInfoCapsule('Building', _buildingName ?? (_isLoadingLocation ? '...' : 'N/A'), capsulePadding),

                  const Spacer(flex: 2),

                  // --- Action Button ---
                  GestureDetector(
                    onTap: _handleNavigationTap,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      padding: EdgeInsets.symmetric(vertical: availableHeight < 650 ? 14 : 18),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Navigate To',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: availableHeight < 650 ? 15 : 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.near_me, color: Colors.white, size: availableHeight < 650 ? 18 : 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCapsule(String label, String value, double padding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          children: [
            Text(
              '$label : ',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
