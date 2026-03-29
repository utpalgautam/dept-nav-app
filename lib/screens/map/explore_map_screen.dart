import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/utils/navigation_utils.dart';

class ExploreMapScreen extends StatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen>
    with SingleTickerProviderStateMixin {
  MaplibreMapController? _mapController;
  bool _isMapReady = false;
  bool _isCentered = true;
  double _currentBearing = 0.0;
  StreamSubscription<Position>? _positionStream;

  // User location state (custom layered blue dot)
  LatLng? _userLocation;
  double _currentHeading = 0.0;
  
  // Animation for smooth movement
  late AnimationController _markerAnimationController;
  LatLng? _previousPosition;
  LatLng? _targetPosition;
  
  // Smoothing: Kalman Filter for jitter reduction
  final KalmanLatLong _kalmanFilter = KalmanLatLong(qMetresPerSecond: 1.5);

  @override
  void initState() {
    super.initState();
    _markerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(_onMarkerAnimationTick);
    _requestLocationAndCenter();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _markerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationAndCenter() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });

        // Animate to user's GPS position once map is ready
        _animateToUser();
      }

      // Listen for bearing and position updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // More frequent updates for smooth movement
        ),
      ).listen((pos) {
        if (!mounted) return;
        
        // Jitter Reduction: Process through Kalman Filter
        final LatLng filteredLatLng = _kalmanFilter.process(
          pos.latitude,
          pos.longitude,
          pos.accuracy,
          pos.timestamp.millisecondsSinceEpoch,
        );
        
        _currentHeading = pos.heading;

        setState(() {
          _userLocation = filteredLatLng;
        });

        // Trigger animation to new position
        if (_targetPosition == null) {
          _previousPosition = filteredLatLng;
          _targetPosition = filteredLatLng;
          _updateUserLocationGeoJson(filteredLatLng, _currentHeading, pos.accuracy);
        } else if (filteredLatLng != _targetPosition) {
          _previousPosition = _targetPosition;
          _targetPosition = filteredLatLng;
          _markerAnimationController.forward(from: 0.0);
        }

        if (_isCentered && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(_userLocation!),
            duration: const Duration(milliseconds: 800),
          );
        }
      });
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  void _animateToUser() {
    if (_mapController == null || _userLocation == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _userLocation!,
          zoom: 17.0,
          tilt: 0,
          bearing: 0,
        ),
      ),
      duration: const Duration(milliseconds: 900),
    );
    setState(() => _isCentered = true);
  }

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
    // Accuracy update is handled in the next stream update or a default value
    _updateUserLocationGeoJson(interpPos, _currentHeading, 20.0);
  }

  void _resetNorth() {
    if (_mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.bearingTo(0),
      duration: const Duration(milliseconds: 500),
    );
    setState(() => _currentBearing = 0.0);
  }

  void _zoomIn() {
    _mapController?.animateCamera(
      CameraUpdate.zoomIn(),
      duration: const Duration(milliseconds: 300),
    );
  }

  void _zoomOut() {
    _mapController?.animateCamera(
      CameraUpdate.zoomOut(),
      duration: const Duration(milliseconds: 300),
    );
  }

  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;

    // Track bearing changes to show compass button
    controller.addListener(() {
      if (!mounted) return;
      final bearing = controller.cameraPosition?.bearing ?? 0.0;
      if ((bearing - _currentBearing).abs() > 0.5) {
        setState(() => _currentBearing = bearing);
      }
    });
  }

  void _onStyleLoaded() {
    setState(() => _isMapReady = true);
    _initUserLocationLayers();
    _animateToUser();
  }

  Future<void> _initUserLocationLayers() async {
    if (_mapController == null) return;
    try {
      await _mapController!.addSource("user-location-source",
          const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

      // 1. Accuracy Circle
      await _mapController!.addLayer(
        "user-location-source",
        "user-location-accuracy",
        const CircleLayerProperties(
          circleColor: '#3b82f6',
          circleOpacity: 0.15,
          circleRadius: 40.0,
          circleBlur: 0.5,
        ),
      );

      // 2. White Halo
      await _mapController!.addLayer(
        "user-location-source",
        "user-location-halo",
        const CircleLayerProperties(
          circleColor: '#FFFFFF',
          circleRadius: 10.0,
          circleOpacity: 1.0,
        ),
      );

      // 3. Blue Dot
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

      // 4. Heading Arrow
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

  @override
  Widget build(BuildContext context) {
    final bool showCompass = _currentBearing.abs() > 1.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          MaplibreMap(
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            initialCameraPosition: CameraPosition(
              target: _userLocation ??
                  const LatLng(11.319972, 75.932639), // NITC campus fallback
              zoom: 17.0,
              tilt: 0,
            ),
            styleString: MapStyle.voyager,
            myLocationEnabled: false, // Using custom layered blue dot
            myLocationRenderMode: MyLocationRenderMode.normal,
            myLocationTrackingMode: MyLocationTrackingMode.none,
            compassEnabled: false, // We use our custom compass button
            attributionButtonPosition: AttributionButtonPosition.bottomLeft,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            scrollGesturesEnabled: true,
          ),

          // ── Back Button (top-left) ───────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: _MapFloatingButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),

          // ── Compass Button (top-right, visible when rotated) ─────────────
          if (showCompass)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, top: 8),
                  child: _CompassButton(
                    bearing: _currentBearing,
                    onTap: _resetNorth,
                  ),
                ),
              ),
            ),

          // ── Zoom Controls (right-side vertical stack) ────────────────────
          Positioned(
            right: 12,
            bottom: 160,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapFloatingButton(icon: Icons.add, onTap: _zoomIn),
                const SizedBox(height: 8),
                _DividerLine(),
                const SizedBox(height: 8),
                _MapFloatingButton(icon: Icons.remove, onTap: _zoomOut),
              ],
            ),
          ),

          // ── Recenter Button (bottom-left) ────────────────────────────────
          Positioned(
            bottom: 40,
            left: 16,
            child: _RecenterButton(onTap: _animateToUser),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Floating Button
// ─────────────────────────────────────────────────────────────────────────────

class _MapFloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapFloatingButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black54,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
      ),
    );
  }
}

// Zoom divider line
class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 1,
      color: Colors.white24,
    );
  }
}

// Compass button (shows N-arrow rotated to current bearing)
class _CompassButton extends StatelessWidget {
  final double bearing;
  final VoidCallback onTap;

  const _CompassButton({required this.bearing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black54,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Transform.rotate(
              angle: -bearing * 3.14159265 / 180,
              child: const Icon(Icons.navigation, color: Colors.blueAccent, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

// Re-centre pill button (Google Maps style)
class _RecenterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RecenterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      shadowColor: Colors.black54,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: -0.785, // 45° tilt = navigation arrow
                child: const Icon(Icons.navigation, color: Colors.blueAccent, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'Re-centre',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.2,
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
// Map Style Definitions
// ─────────────────────────────────────────────────────────────────────────────

class MapStyle {
  /// Carto Dark Matter GL — free, no API key required
  static const String darkMatter =
      'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json';

  /// Carto Voyager (light, for reference)
  static const String voyager =
      'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json';
}
