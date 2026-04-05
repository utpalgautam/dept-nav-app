import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../models/building_model.dart';
import '../../core/constants/app_constants.dart';
import 'widgets/turn_by_turn_widget.dart';
import 'widgets/custom_navigation_controls.dart';
import 'widgets/start_navigation_header.dart';
import 'indoor_navigation_screen.dart';
import 'entry_point_confirmation_screen.dart';
import '../../core/utils/navigation_utils.dart';
import '../../models/location_model.dart';
import '../../services/firestore_service.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'navigation_completion_screen.dart';

enum MapFollowMode { northUp, headingUp }

class OutdoorNavigationScreen extends StatefulWidget {
  final BuildingModel? targetBuilding;
  final EntryPoint? targetEntryPoint;
  final String? destinationId;
  final String? destinationName;
  final double? destLat;
  final double? destLng;

  const OutdoorNavigationScreen({
    super.key,
    this.targetBuilding,
    this.targetEntryPoint,
    this.destinationId,
    this.destinationName,
    this.destLat,
    this.destLng,
  });

  @override
  State<OutdoorNavigationScreen> createState() =>
      _OutdoorNavigationScreenState();
}

class _OutdoorNavigationScreenState extends State<OutdoorNavigationScreen>
    with SingleTickerProviderStateMixin {
  // ── Map ──────────────────────────────────────────────────────────────────
  MaplibreMapController? _mapController;
  bool _isMapReady = false;
  bool _isTransitioningToIndoor = false;
  bool _isCentered = true;
  double _currentBearing = 0.0;
  MapFollowMode _followMode = MapFollowMode.headingUp; // Default to Heading-Up for vertical alignment
  bool _isAutoRotating = false;
  DateTime? _lastDrawTimestamp; // Throttling map drawing
  bool _hasSpokenDestination = false;
  LocationModel? _destinationLocation;
  final FirestoreService _firestoreService = FirestoreService();
  DateTime? _navigationStartTime;

  // ── User Marker (smooth animated blue dot) ────────────────────────────
  Symbol? _userMarker;
  Symbol? _destinationMarker;
  LatLng? _currentDestMarkerPos;
  late AnimationController _markerAnimationController;
  LatLng? _previousPosition;
  LatLng? _targetPosition;
  double _currentHeading = 0;

  // ── Passive tracking (pre-navigation) ────────────────────────────────
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _markerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // Faster interpolation between GPS fixes
    )..addListener(_onMarkerAnimationTick);
    _fetchDestinationDetails();
  }

  Future<void> _fetchDestinationDetails() async {
    if (widget.destinationId != null) {
      final loc = await _firestoreService.getLocation(widget.destinationId!);
      if (mounted) {
        setState(() => _destinationLocation = loc);
      }
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _markerAnimationController.dispose();
    
    // Cleanup navigation provider on screen exit
    final provider = Provider.of<NavigationProvider>(context, listen: false);
    provider.removeListener(_onProviderUpdated);
    
    // Stop navigation state if we are still in this screen's context
    if (!provider.isIndoor) {
       provider.stopNavigation();
    }
    
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  // Marker animation (smooth interpolation between GPS positions)
  // ─────────────────────────────────────────────────────────────────
  void _onMarkerAnimationTick() {
    if (_previousPosition == null ||
        _targetPosition == null ||
        _mapController == null) return;

    final double t = _markerAnimationController.value;
    final double lat = _previousPosition!.latitude +
        (_targetPosition!.latitude - _previousPosition!.latitude) * t;
    final double lng = _previousPosition!.longitude +
        (_targetPosition!.longitude - _previousPosition!.longitude) * t;

    final LatLng interpPos = LatLng(lat, lng);
    final provider = Provider.of<NavigationProvider>(context, listen: false);
    final double accuracy = provider.currentPosition?.accuracy ?? 20.0;

    _updateUserLocationGeoJson(interpPos, _currentHeading, accuracy);
  }

  // ─────────────────────────────────────────────────────────────────
  // Map Lifecycle
  // ─────────────────────────────────────────────────────────────────
  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;

    // Track bearing for compass button visibility
    controller.addListener(() {
      if (!mounted) return;
      final bearing = controller.cameraPosition?.bearing ?? 0.0;
      if ((bearing - _currentBearing).abs() > 0.5) {
        setState(() => _currentBearing = bearing);
      }
    });
  }

  void _onStyleLoaded() async {
    setState(() => _isMapReady = true);

    _initUserLocationLayers();
    _initRouteLayers();
    _initDestinationMarkerLayers();
    _add3DBuildings();
    _addBuildingMarkers();

    if (widget.destLat != null && widget.destLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.destLat!, widget.destLng!),
            zoom: 16,
          ),
        ),
      );
      _addDestinationMarker();
    }

    final provider = Provider.of<NavigationProvider>(context, listen: false);

    if (widget.destLat != null &&
        widget.destLng != null) {
      provider.previewRoute(
        NavigationPoint(lat: widget.destLat!, lng: widget.destLng!),
        targetBuilding: widget.targetBuilding,
        entryPoint: widget.targetEntryPoint,
      );
    }

    provider.addListener(_onProviderUpdated);
    _onProviderUpdated();

    if (!provider.isNavigating) {
      _startPassiveTracking();
      // Speak destination flow on load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasSpokenDestination) {
          _hasSpokenDestination = true;
          final building = widget.targetBuilding?.name ?? "Destination";
          final floor = _destinationLocation?.floor == 0 ? "Ground Floor" 
              : (_destinationLocation?.floor == 1 ? "First Floor" 
              : (_destinationLocation?.floor == 2 ? "Second Floor" 
              : (_destinationLocation?.floor == 3 ? "Third Floor" 
              : (_destinationLocation?.floor != null ? "Floor ${_destinationLocation!.floor}" : "Second Floor"))));
          final cabin = widget.destinationName ?? "";
          provider.speak("Navigating to $building. Flow: $building, $floor, $cabin.");
        }
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Camera Controls
  // ─────────────────────────────────────────────────────────────────
  void _recenter() {
    final provider = Provider.of<NavigationProvider>(context, listen: false);
    final pos = provider.currentPosition;
    if (pos != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 18,
            bearing: pos.heading,
            tilt: 45,
          ),
        ),
        duration: const Duration(milliseconds: 800),
      );
      setState(() => _isCentered = true);
    } else if (_targetPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_targetPosition!),
        duration: const Duration(milliseconds: 800),
      );
      setState(() => _isCentered = true);
    }
  }

  void _resetNorth() {
    _mapController?.animateCamera(
      CameraUpdate.bearingTo(0),
      duration: const Duration(milliseconds: 500),
    );
    setState(() => _currentBearing = 0.0);
    setState(() => _followMode = MapFollowMode.northUp);
  }

  void _toggleFollowMode() {
    setState(() {
      _followMode = _followMode == MapFollowMode.northUp
          ? MapFollowMode.headingUp
          : MapFollowMode.northUp;
      
      if (_followMode == MapFollowMode.northUp) {
        _resetNorth();
      } else {
        _recenter();
      }
    });
  }

  void _zoomIn() => _mapController?.animateCamera(
        CameraUpdate.zoomIn(),
        duration: const Duration(milliseconds: 300),
      );

  void _zoomOut() => _mapController?.animateCamera(
        CameraUpdate.zoomOut(),
        duration: const Duration(milliseconds: 300),
      );

  // ─────────────────────────────────────────────────────────────────
  // Passive Location Tracking (pre-navigation)
  // ─────────────────────────────────────────────────────────────────
  void _startPassiveTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1, // Update every meter instead of every 5m
      ),
    ).listen((Position position) {
      if (!mounted) return;
      final navProvider =
          Provider.of<NavigationProvider>(context, listen: false);
      if (!navProvider.isNavigating) {
        _updateLiveUserMarker(position);
      }
    });
  }


  void _updateLiveUserMarker(Position position) async {
    if (_mapController == null || !_isMapReady) return;

    final latLng = LatLng(position.latitude, position.longitude);
    _currentHeading = position.heading;

    if (_targetPosition == null) {
      _previousPosition = latLng;
      _targetPosition = latLng;
      _updateUserLocationGeoJson(latLng, _currentHeading, position.accuracy);
    } else if (latLng != _targetPosition) {
      _previousPosition = _targetPosition;
      _targetPosition = latLng;
      _markerAnimationController.forward(from: 0.0);
    }

    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    if (!navProvider.isNavigating) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
          target: latLng,
          zoom: 18,
          bearing: position.heading,
          tilt: 45,
        )),
        duration: const Duration(milliseconds: 400), // Snappy pre-nav camera centering
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Provider Updates (during active navigation)
  // ─────────────────────────────────────────────────────────────────
  void _onProviderUpdated() {
    final provider = Provider.of<NavigationProvider>(context, listen: false);

    if (provider.targetEntryPoint != null && _isMapReady && _mapController != null) {
      final ep = provider.targetEntryPoint!;
      final epLatLng = LatLng(ep.latitude, ep.longitude);
      
      if (_currentDestMarkerPos == null) {
        _drawDynamicDestinationMarker(epLatLng, entryPoint: ep);
      } else if (_currentDestMarkerPos!.latitude != epLatLng.latitude || _currentDestMarkerPos!.longitude != epLatLng.longitude) {
        if (_destinationMarker != null) {
          _mapController!.removeSymbol(_destinationMarker!);
          _destinationMarker = null;
        }
        _drawDynamicDestinationMarker(epLatLng, entryPoint: ep);
      }
    }

    if (provider.currentRoute != null && _isMapReady) {
      _drawRoute(
        provider.remainingRouteCoordinates,
        fullPoints: provider.currentRoute?.coordinates,
      );
    }

    if (provider.isNavigating &&
        provider.snappedPosition != null &&
        _isMapReady) {
      final newPosition = provider.snappedPosition!;
      _currentHeading = provider.currentPosition?.heading ?? 0;

      if (_targetPosition == null) {
        _previousPosition = newPosition;
        _targetPosition = newPosition;
        _updateUserMarkerNavigating(newPosition, _currentHeading);
      } else if (newPosition != _targetPosition) {
        _previousPosition = _targetPosition;
        _targetPosition = newPosition;
        _markerAnimationController.forward(from: 0.0);
      }

      if (_isCentered) {
        final double targetBearing = (_followMode == MapFollowMode.headingUp) 
            ? (provider.currentPosition?.heading ?? 0) 
            : 0;
        
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(
            target: newPosition,
            zoom: 19,
            bearing: targetBearing,
            tilt: 55,
          )),
          duration: const Duration(milliseconds: 450), // Snappy camera follow during navigation
        );
      }
    }
  }

  // Removed invalid _updateUserLocationLayersForMode method as 'map' alignment 
  // already correctly points the icon 'Up' when map bearing matches user heading.

  // ─────────────────────────────────────────────────────────────────
  // Map Layers
  // ─────────────────────────────────────────────────────────────────
  Future<void> _add3DBuildings() async {
    if (_mapController == null) return;
    try {
      await _mapController!.addLayer(
        "carto",
        "3d-buildings",
        const FillExtrusionLayerProperties(
          fillExtrusionColor: '#E0E0E0', 
          fillExtrusionHeight: ["get", "render_height"],
          fillExtrusionBase: ["get", "render_min_height"],
          fillExtrusionOpacity: 0.7,
        ),
        belowLayerId: "place_city_r5",
        minzoom: 15.0,
      );
    } catch (e) {
      debugPrint("Error adding 3D buildings: $e");
    }
  }

  Future<void> _initRouteLayers() async {
    if (_mapController == null) return;
    try {
      // 1. Add Traveled Route Source & Layer
      await _mapController!.addSource("route-traveled-source",
          const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));
      await _mapController!.addLayer(
        "route-traveled-source",
        "route-traveled",
        const LineLayerProperties(
          lineColor: '#3a4060',
          lineWidth: 6.0,
          lineOpacity: 0.6,
          lineJoin: 'round',
          lineCap: 'round',
        ),
      );

      // 2. Add Active Route Glow Source & Layer (The outer white glow)
      await _mapController!.addSource("route-source",
          const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

      await _mapController!.addLayer(
        "route-source",
        "route-glow",
        const LineLayerProperties(
          lineColor: '#FFFFFF',
          lineWidth: 10.0,
          lineOpacity: 0.25,
          lineJoin: 'round',
          lineCap: 'round',
        ),
        belowLayerId: "3d-buildings", // Under buildings and custom markers
      );

      // 3. Add Active Route Main Layer (The blue dotted line)
      await _mapController!.addLayer(
        "route-source",
        "route-main",
        const LineLayerProperties(
          lineColor: '#3b82f6', // Premium Google blue
          lineWidth: 6.0,
          lineJoin: 'round',
          lineCap: 'round',
          lineDasharray: [0.1, 1.8], // Dotted pattern
        ),
        belowLayerId: "3d-buildings",
      );

      // 4. Add Active Segment Highlight Source & Layer (The solid blue line for current leg)
      await _mapController!.addSource("route-segment-source",
          const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

      await _mapController!.addLayer(
        "route-segment-source",
        "route-segment-highlight",
        const LineLayerProperties(
          lineColor: '#3b82f6', // Same blue but solid
          lineWidth: 6.0,
          lineJoin: 'round',
          lineCap: 'round',
        ),
        belowLayerId: "3d-buildings",
      );

      // 5. Add Connection Line (User to Route Start)
      await _mapController!.addSource("route-connection-source",
          const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

      await _mapController!.addLayer(
        "route-connection-source",
        "route-connection",
        const LineLayerProperties(
          lineColor: '#3b82f6',
          lineWidth: 4.0,
          lineOpacity: 0.5,
          lineDasharray: [0.2, 2.0],
          lineJoin: 'round',
          lineCap: 'round',
        ),
        belowLayerId: "user-location-halo", // Behind the user dot
      );

      // 6. Add Connection Line (Route End to Destination)
      await _mapController!.addSource("route-destination-connection-source",
          const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

      await _mapController!.addLayer(
        "route-destination-connection-source",
        "route-destination-connection",
        const LineLayerProperties(
          lineColor: '#3b82f6',
          lineWidth: 4.0,
          lineOpacity: 0.5,
          lineDasharray: [0.2, 2.0],
          lineJoin: 'round',
          lineCap: 'round',
        ),
        belowLayerId: "destination-marker-layer", // Behind the destination pin
      );
    } catch (e) {
      debugPrint("Error initializing route layers: $e");
    }
  }

  Future<void> _initUserLocationLayers() async {
    if (_mapController == null) return;
    try {
      await _mapController!.addSource("user-location-source",
          const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

      // 1. Accuracy Circle (Bottom-most)
      await _mapController!.addLayer(
        "user-location-source",
        "user-location-accuracy",
        const CircleLayerProperties(
          circleColor: '#3b82f6',
          circleOpacity: 0.15,
          circleRadius: 40.0, // Fixed radius for visual feedback
          circleBlur: 0.5,
        ),
      );

      // 2. White Halo for the Blue Dot
      await _mapController!.addLayer(
        "user-location-source",
        "user-location-halo",
        const CircleLayerProperties(
          circleColor: '#FFFFFF',
          circleRadius: 10.0,
          circleOpacity: 1.0,
        ),
      );

      // 3. Blue Dot (Center)
      await _mapController!.addLayer(
        "user-location-source",
        "user-location-dot",
        const CircleLayerProperties(
          circleColor: '#3b82f6',
          circleRadius: 8.0,
          circleOpacity: 1.0,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 0.5,
        ),
      );

      // 4. Heading Arrow (Top-most)
      await _mapController!.addLayer(
        "user-location-source",
        "user-location-arrow",
        const SymbolLayerProperties(
          iconImage: 'assets/icons/navigation_marker.png',
          iconSize: 0.45,
          iconRotate: ["get", "bearing"],
          iconRotationAlignment: 'map',
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ),
      );
    } catch (e) {
      debugPrint("Error initializing user location layers: $e");
    }
  }

  void _updateUserLocationGeoJson(LatLng pos, double heading, double accuracy) async {
    if (_mapController == null) return;
    
    final geojson = {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [pos.longitude, pos.latitude],
          },
          "properties": {
            "bearing": heading,
            "accuracy": accuracy,
          },
        }
      ]
    };

    await _mapController!.setGeoJsonSource("user-location-source", geojson);
  }

  Future<void> _initDestinationMarkerLayers() async {
    if (_mapController == null) return;
    try {
      await _mapController!.addSource("destination-source",
          const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

      await _mapController!.addLayer(
        "destination-source",
        "destination-marker-layer",
        const SymbolLayerProperties(
          iconImage: ["get", "icon-id"], // Data-driven icon image
          iconSize: 0.8,
          iconAnchor: 'bottom',
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ),
        belowLayerId: "user-location-accuracy", // Show below user but above route
      );
    } catch (e) {
      debugPrint("Error initializing destination marker layers: $e");
    }
  }

  void _updateUserMarkerNavigating(LatLng position, double heading) async {
    // No longer using single symbol, handled by GeoJSON layers
  }

  void _drawRoute(List<LatLng> points, {List<LatLng>? fullPoints}) async {
    if (_mapController == null || points.isEmpty) return;

    // Performance Optimization: Throttle drawing to ~25 FPS (every 40ms)
    // Faster redraws make the remaining route line shrink in near real-time.
    final now = DateTime.now();
    if (_lastDrawTimestamp != null) {
      if (now.difference(_lastDrawTimestamp!).inMilliseconds < 40) {
        return;
      }
    }
    _lastDrawTimestamp = now;

    try {
      final provider = Provider.of<NavigationProvider>(context, listen: false);

      // 1. Update Active Route (Main + Glow)
      final activeGeoJson = NavigationUtils.toGeoJson(points);
      await _mapController!.setGeoJsonSource("route-source", activeGeoJson);

      // 1.5 Update Active Segment (Next Leg)
      if (provider.isNavigating) {
        final segmentGeoJson = NavigationUtils.toGeoJson(provider.nextSegmentCoordinates);
        await _mapController!.setGeoJsonSource("route-segment-source", segmentGeoJson);
      }

      // 2. Update Traveled Route
      if (fullPoints != null && fullPoints.isNotEmpty) {
        // Assume points is a sublist of fullPoints (remaining points)
        // Everything before 'points.first' in 'fullPoints' is traveled
        int firstIndex = 0;
        for (int i = 0; i < fullPoints.length; i++) {
          if (fullPoints[i].latitude == points.first.latitude &&
              fullPoints[i].longitude == points.first.longitude) {
            firstIndex = i;
            break;
          }
        }

        if (firstIndex > 0) {
          final traveledPoints = fullPoints.sublist(0, firstIndex + 1);
          final traveledGeoJson = NavigationUtils.toGeoJson(traveledPoints);
          await _mapController!.setGeoJsonSource("route-traveled-source", traveledGeoJson);
        } else {
          // Clear traveled source if we are at the beginning
          await _mapController!.setGeoJsonSource("route-traveled-source",
              {"type": "FeatureCollection", "features": []});
        }
      }

      // 3. Update Connection Line (User to Route Start)
      if (provider.snappedPosition != null && points.isNotEmpty) {
        final connectionPoints = [provider.snappedPosition!, points.first];
        final connectionGeoJson = NavigationUtils.toGeoJson(connectionPoints);
        await _mapController!.setGeoJsonSource("route-connection-source", connectionGeoJson);
      } else if (_targetPosition != null && points.isNotEmpty) {
        final connectionPoints = [_targetPosition!, points.first];
        final connectionGeoJson = NavigationUtils.toGeoJson(connectionPoints);
        await _mapController!.setGeoJsonSource("route-connection-source", connectionGeoJson);
      } else {
        await _mapController!.setGeoJsonSource("route-connection-source",
            {"type": "FeatureCollection", "features": []});
      }

      // 4. Update Connection Line (Route End to Destination)
      if (points.isNotEmpty && _currentDestMarkerPos != null) {
        final connectionPoints = [points.last, _currentDestMarkerPos!];
        final connectionGeoJson = NavigationUtils.toGeoJson(connectionPoints);
        await _mapController!.setGeoJsonSource("route-destination-connection-source", connectionGeoJson);
      } else {
        await _mapController!.setGeoJsonSource("route-destination-connection-source",
            {"type": "FeatureCollection", "features": []});
      }

      if (!provider.isNavigating) {
        LatLngBounds bounds = _getBounds(points);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds,
              top: 150, left: 50, right: 50, bottom: 250),
        );
      }
    } catch (e) {
      debugPrint('Error drawing route: $e');
    }
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
          southwest: const LatLng(11.3190, 75.9310),
          northeast: const LatLng(11.3210, 75.9340));
    }
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _addBuildingMarkers() async {
    if (_mapController == null) return;

    final buildings = [
      {'name': 'Main Building', 'lat': 11.320, 'lng': 75.932},
      {'name': 'CS Dept', 'lat': 11.322, 'lng': 75.934},
    ];

    for (var b in buildings) {
      try {
        await _mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(b['lat'] as double, b['lng'] as double),
            iconImage: 'assets/icons/building_marker.png',
            iconSize: 0.5,
            textField: b['name'] as String,
            textOffset: const Offset(0, 1.5),
            textSize: 12,
            textColor: '#FFFFFF',
            textHaloColor: '#000000',
            textHaloWidth: 2,
          ),
        );
      } catch (e) {
        debugPrint('Error adding building marker: $e');
      }
    }
  }

  Future<void> _addDestinationMarker() async {
    debugPrint('[_addDestinationMarker] Controller: ${_mapController != null}, Lat: ${widget.destLat}, Lng: ${widget.destLng}');
    if (_mapController == null ||
        widget.destLat == null ||
        widget.destLng == null) {
      debugPrint('[_addDestinationMarker] Returning early - missing requirements');
      return;
    }
    
    final pos = LatLng(
      widget.targetEntryPoint?.latitude ?? widget.destLat!,
      widget.targetEntryPoint?.longitude ?? widget.destLng!,
    );
    await _addCustomDestinationMarker(pos, entryPoint: widget.targetEntryPoint);
  }

  Future<void> _drawDynamicDestinationMarker(LatLng position, {EntryPoint? entryPoint}) async {
    await _addCustomDestinationMarker(position, entryPoint: entryPoint);
  }

  Future<void> _addCustomDestinationMarker(LatLng position, {EntryPoint? entryPoint}) async {
    debugPrint('[_addCustomDestinationMarker] Position: $position');
    if (_mapController == null) {
      debugPrint('[_addCustomDestinationMarker] Controller is null');
      return;
    }

    try {
      final effectiveEntryPoint = entryPoint ?? widget.targetEntryPoint;
      final building = widget.targetBuilding;
      
      debugPrint('[_addCustomDestinationMarker] EntryPoint: ${effectiveEntryPoint?.id}, Building: ${building?.id}');
      
      // 1. Get Image
      ui.Image? markerImage;
      String? imageStr = effectiveEntryPoint?.imageUrl ?? building?.imageUrl;
      debugPrint('[_addCustomDestinationMarker] Found Image String: ${imageStr != null}');
      
      if (imageStr != null && imageStr.isNotEmpty) {
        if (imageStr.startsWith('http')) {
          // It's a URL
          final response = await http.get(Uri.parse(imageStr));
          if (response.statusCode == 200) {
            markerImage = await _decodeImage(response.bodyBytes);
          }
        } else {
          // It's base64
          final raw = imageStr.contains(',') ? imageStr.split(',').last : imageStr;
          final bytes = base64Decode(raw);
          markerImage = await _decodeImage(bytes);
        }
      }

      // 2. Create the composite pin image
      final iconId = "dest_marker_${DateTime.now().millisecondsSinceEpoch}";
      final bytes = await _createMarkerImage(markerImage);
      debugPrint('[_addCustomDestinationMarker] Created Image Bytes: ${bytes.length}');
      
      // 3. Add to Map
      await _mapController!.addImage(iconId, bytes);
      debugPrint('[_addCustomDestinationMarker] Added image to map: $iconId');

      // 4. Update the GeoJSON source
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [position.longitude, position.latitude],
            },
            "properties": {
              "icon-id": iconId,
            },
          }
        ]
      };

      await _mapController!.setGeoJsonSource("destination-source", geojson);
      debugPrint('[_addCustomDestinationMarker] Source updated successfully');
      _currentDestMarkerPos = position;
      
    } catch (e) {
      debugPrint('Error adding custom destination marker: $e');
      // Fallback to basic marker if something goes wrong
      _drawFallbackMarker(position);
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) => completer.complete(img));
    return completer.future;
  }

  Future<Uint8List> _createMarkerImage(ui.Image? doorImage) async {
    const double width = 120.0;
    const double height = 160.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()..color = Colors.black;
    
    // Draw Pin Body (SVG-like path)
    final path = Path();
    path.moveTo(width / 2, height); // Tip
    path.lineTo(width * 0.1, height * 0.45);
    path.arcToPoint(Offset(width * 0.9, height * 0.45), radius: const Radius.circular(width / 2));
    path.close();
    canvas.drawPath(path, paint);

    // Draw Circular Cutout at Top
    const double circleRadius = width * 0.38;
    final Offset circleCenter = Offset(width / 2, width / 2);
    
    // If we have an image, clip and draw it
    if (doorImage != null) {
      canvas.save();
      final clipPath = Path()..addOval(Rect.fromCircle(center: circleCenter, radius: circleRadius));
      canvas.clipPath(clipPath);
      
      // Draw image to fit the circle
      double scale = (circleRadius * 2) / (doorImage.width > doorImage.height ? doorImage.height : doorImage.width);
      canvas.drawImageRect(
        doorImage,
        Rect.fromLTWH(0, 0, doorImage.width.toDouble(), doorImage.height.toDouble()),
        Rect.fromCircle(center: circleCenter, radius: circleRadius),
        Paint(),
      );
      canvas.restore();
    } else {
      // Fallback: draw a white circle if no image
      canvas.drawCircle(circleCenter, circleRadius, Paint()..color = Colors.white);
    }

    // Add a premium border to the circle
    canvas.drawCircle(circleCenter, circleRadius, Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _drawFallbackMarker(LatLng position) async {
     _destinationMarker = await _mapController!.addSymbol(
        SymbolOptions(
          geometry: position,
          iconImage: 'assets/icons/navigation_marker.png', // Temporary fallback
          iconSize: 0.5,
          iconAnchor: 'center',
        ),
      );
  }

  // ─────────────────────────────────────────────────────────────────
  // Navigation Actions
  // ─────────────────────────────────────────────────────────────────
  void _startNavigation(NavigationProvider provider) {
    if (provider.currentRoute != null) {
      setState(() {
        _followMode = MapFollowMode.headingUp; // Ensure HeadingUp on start
        _isCentered = true;
      });
      _navigationStartTime = DateTime.now();
      provider.startOutdoorNavigation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              provider.routeError ?? 'Unable to calculate route. Try again.'),
          backgroundColor: const Color(0xFF1C2333),
        ),
      );
    }
  }

  void _stopNavigation(NavigationProvider provider) {
    provider.stopNavigation();
    provider.removeListener(_onProviderUpdated);
    Navigator.pop(context);
  }

  void _navigateToConfirmationScreen(BuildContext context) {
    final provider = Provider.of<NavigationProvider>(context, listen: false);
    final effectiveEntryPoint = provider.targetEntryPoint ?? widget.targetEntryPoint;

    if (widget.targetBuilding != null && effectiveEntryPoint != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EntryPointConfirmationScreen(
            buildingId: widget.targetBuilding!.id,
            buildingName: widget.targetBuilding!.name,
            entryPointId: effectiveEntryPoint.id,
            entryPointImageUrl: effectiveEntryPoint.imageUrl ?? widget.targetBuilding!.imageUrl,
            destinationLocationId: widget.destinationId,
          ),
        ),
      );
    }
  }

  void _navigateToIndoorScreen(BuildContext context) {
    final provider = Provider.of<NavigationProvider>(context, listen: false);
    final effectiveEntryPoint = provider.targetEntryPoint ?? widget.targetEntryPoint;

    if (widget.targetBuilding != null && effectiveEntryPoint != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => IndoorNavigationScreen(
            buildingId: widget.targetBuilding!.id,
            buildingName: widget.targetBuilding!.name,
            floor: 0,
            entryPointId: effectiveEntryPoint.id, // entryPointId will match entrance node label per user request
            destinationLocationId: widget.destinationId,
          ),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const bool showCompass = true;
    final auth = context.watch<app_auth.AuthProvider>();
    final metric = auth.currentUser?.preferences['distanceMetric'] ?? 'Meters';

    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        // Trigger indoor transition
        if (navProvider.isIndoor &&
            navProvider.isNavigating &&
            !_isTransitioningToIndoor) {
          _isTransitioningToIndoor = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.targetBuilding != null) {
              // Has an indoor leg → transition to confirmation screen
              _navigateToConfirmationScreen(context);
            } else {
              // Outdoor-only destination reached → show completion screen
              final elapsed = _navigationStartTime != null
                  ? DateTime.now()
                      .difference(_navigationStartTime!)
                      .inMinutes
                  : 0;
              final route = navProvider.currentRoute;
              final distMeters = route != null
                  ? route.distance
                  : 0.0;
              navProvider.stopNavigation();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => NavigationCompletionScreen(
                    destinationName:
                        widget.destinationName ?? 'Destination',
                    roomNumber: _destinationLocation?.roomNumber,
                    floor: _destinationLocation?.floor != null
                        ? 'Floor ${_destinationLocation!.floor}'
                        : null,
                    buildingName: widget.targetBuilding?.name,
                    timeTakenMinutes: elapsed,
                    distanceMeters: distMeters,
                    distanceMetric: metric,
                    isIndoorOnly: false,
                  ),
                ),
              );
            }
          });
        }

        return PopScope(
          canPop: true,
          onPopInvoked: (didPop) {
            if (didPop) {
              navProvider.stopNavigation();
            }
          },
          child: Scaffold(
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                // ── MapLibre Map (Dark Matter) ─────────────────────────────
                MaplibreMap(
                  onMapCreated: _onMapCreated,
                  onStyleLoadedCallback: _onStyleLoaded,
                  minMaxZoomPreference: MinMaxZoomPreference(0, AppConstants.getMaxZoom(auth.currentUser?.preferences['outdoorNavTheme'])),
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(AppConstants.campusLat, AppConstants.campusLng),
                    zoom: AppConstants.defaultMapZoom,
                    tilt: 45,
                  ),
                  styleString: MapStyle.getStyle(
                    auth.currentUser?.preferences['outdoorNavTheme']
                  ),
                  myLocationEnabled: false, // custom marker for smooth animation
                  myLocationRenderMode: MyLocationRenderMode.normal,
                  compassEnabled: false, // custom compass button
                  attributionButtonPosition: AttributionButtonPosition.bottomLeft,
                  zoomGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                ),
  
                // ── Pre-navigation Destination Header ──────────────────────
                if (!navProvider.isNavigating)
                  Positioned(
                    top: 50,
                    left: 16,
                    right: 16,
                    child: StartNavigationHeader(
                      buildingName: widget.targetBuilding?.name ?? "Building",
                      floorNumber: _destinationLocation?.floor,
                      cabinName: widget.destinationName ?? "Cabin",
                      isSpeaking: navProvider.isSpeaking,
                    ),
                  ),
  
                // ── Turn-by-Turn Header ────────────────────────────────────
                if (navProvider.isNavigating)
                  Positioned(
                    top: 50,
                    left: 16,
                    right: 16,
                    child: TurnByTurnWidget(
                      instruction: navProvider.currentInstruction ??
                          'Head to destination',
                      distance: navProvider.distanceToNextStep != null
                          ? NavigationUtils.formatDistance(navProvider.distanceToNextStep!, metric)
                          : '...',
                      sign: navProvider.currentSign,
                      nextInstruction: navProvider.nextInstruction,
                      nextSign: navProvider.nextSign,
                      isSpeaking: navProvider.isSpeaking,
                      isUrgent: navProvider.isApproachingTurn,
                      onClose: () => _stopNavigation(navProvider),
                    ),
                  ),
  
                // ── Top-Right Floating Button Stack ──────────────────────
                if (navProvider.isNavigating)
                  SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, top: 110),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Compass
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NavFloatingButton(
                              child: Transform.rotate(
                                angle: -_currentBearing * 3.14159265 / 180,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(Icons.navigation,
                                        color: Colors.white, size: 26),
                                    ClipRect(
                                      clipper: _TopHalfClipper(),
                                      child: const Icon(Icons.navigation,
                                          color: Colors.redAccent, size: 26),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: _resetNorth,
                            ),
                          ),
                          
  
                          // 2. Voice Toggle (if navigating)
                          if (navProvider.isNavigating)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _NavFloatingButton(
                                child: Icon(
                                  navProvider.isVoiceEnabled
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_off_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onTap: navProvider.toggleVoice,
                              ),
                            ),
  
                          // 4. Follow Mode Toggle
                          if (!navProvider.isNavigating)
                            _NavFloatingButton(
                              child: Icon(
                                _followMode == MapFollowMode.headingUp
                                    ? Icons.navigation_rounded
                                    : Icons.explore_rounded,
                                color: _followMode == MapFollowMode.headingUp
                                    ? Colors.blueAccent
                                    : Colors.white,
                                size: 24,
                              ),
                              onTap: _toggleFollowMode,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
  
                // ── Zoom Controls (right-side) ─────────────────────────────
                if (navProvider.isNavigating)
                  Positioned(
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 150,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _NavFloatingButton(
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 24),
                          onTap: _zoomIn,
                        ),
                        const SizedBox(height: 12),
                        _NavFloatingButton(
                          child: const Icon(Icons.remove,
                              color: Colors.white, size: 24),
                        onTap: _zoomOut,
                        ),
                      ],
                    ),
                  ),
  
                // ── Recenter Button (bottom-left) ──────────────────────────
                if (!_isCentered)
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + (navProvider.isNavigating ? 140 : 160),
                    left: 16,
                    child: _RecenterPill(onTap: _recenter),
                  ),
  
                // ── Bottom Navigation Controls ─────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CustomNavigationControls(
                    isNavigating: navProvider.isNavigating,
                    isLoading: navProvider.isLoadingRoute,
                    instruction: navProvider.isNavigating
                        ? (navProvider.currentInstruction ?? 'Follow the route')
                        : (widget.targetBuilding?.name ?? 'Head to Entrance'),
                    distance: navProvider.distanceToDestination != null
                        ? NavigationUtils.formatDistance(navProvider.distanceToDestination!, metric)
                        : '...',
                    time: navProvider.remainingTime != null
                        ? '${navProvider.remainingTime} min'
                        : (navProvider.currentRoute != null
                            ? '${(navProvider.currentRoute!.time / 60000).ceil()} min'
                            : '...'),
                    arrivalTime: navProvider.arrivalTime,
                    base64Image: widget.targetEntryPoint?.imageUrl ?? widget.targetBuilding?.imageUrl,
                    onStartNavigation: () => _startNavigation(navProvider),
                    onStopNavigation: () => _stopNavigation(navProvider),
                    onConfirmArrival: () =>
                        navProvider.switchToIndoorNavigation(),
                  ),
                ),
  
                // ── Arrival overlay removed: NavigationCompletionScreen handles arrival UI
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Destination Preview Card
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
class _NavFloatingButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _NavFloatingButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black45,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(width: 46, height: 46, child: Center(child: child)),
      ),
    );
  }
}

class _RecenterPill extends StatelessWidget {
  final VoidCallback onTap;
  const _RecenterPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: -0.785,
                child: const Icon(Icons.navigation,
                    color: Colors.black, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'Re-centre',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map Style
// ─────────────────────────────────────────────────────────────────────────────


class _TopHalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width, size.height / 2);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
