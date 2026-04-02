import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/building_model.dart';
import '../models/floor_model.dart';
import '../services/graphhopper_service.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/navigation_utils.dart';

import '../services/voice_navigation_service.dart';

class NavigationPoint {
  final double lat;
  final double lng;

  const NavigationPoint({required this.lat, required this.lng});
}

class NavigationProvider extends ChangeNotifier {
  final GraphHopperService _graphHopperService = GraphHopperService();
  final VoiceNavigationService _voiceService = VoiceNavigationService();
  
  bool _isNavigating = false;
  bool _isIndoor = false;
  bool _isLoadingRoute = false;
  bool _isRerouting = false;
  
  NavigationPoint? _destination;
  EntryPoint? _targetEntryPoint;
  BuildingModel? _targetBuilding;

  NavigationRoute? _currentRoute;
  String? _currentInstruction;
  int _currentInstructionIndex = 0;
  double? _distanceToNextStep;
  double? _distanceToDestination;
  String? _routeError;
  List<LatLng> _remainingRouteCoordinates = [];
  List<LatLng> _nextSegmentCoordinates = [];
  
  Position? _currentPosition; // Raw filtered position
  LatLng? _snappedPosition; // Snapped and smoothed for UI
  DateTime? _lastRerouteTime; // Throttling reroutes
  DateTime? _lastUpdateTimestamp; // Throttling GPS processing
  
  // Smoothing: Kalman Filter for jitter reduction
  final KalmanLatLong _kalmanFilter = KalmanLatLong(qMetresPerSecond: 3.0); // Higher responsiveness for real-time tracking
  
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<Position> _positionBuffer = [];
  int _positionUpdateCount = 0;
  int _deviationCount = 0; // Tracks consecutive off-route readings
  
  // PDR State
  bool _isPdrEnabled = false;
  double? _indoorX;
  double? _indoorY;
  IndoorGraph? _currentIndoorGraph;
  GraphEdge? _currentSnappedEdge;
  List<GraphNode> _currentIndoorPath = [];
  int _nextIndoorNodeIndex = 1;
  String _currentIndoorInstruction = "Starting navigation...";
  bool _isMapRotationEnabled = false;
  String _lastSpokenInstruction = "";
  double _currentHeading = 0.0; // In radians
  double _pdrHeadingOffset = 0.0;
  bool _isPdrInitialized = false;
  
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<MagnetometerEvent>? _magSubscription;
  
  // Sensor buffers for PDR
  final List<double> _accelMagnitudeBuffer = [];
  static const int _bufferSize = 20;
  static const double _stepThresholdMin = 11.0; 
  static const double _stepThresholdMax = 13.0;
  static const double _filterAlpha = 0.15; // Low-pass filter smoothing factor
  double _lastFilteredMagnitude = 0.0;
  DateTime? _lastStepTime;

  // PDR Configuration
  static const double _mapUnitsPerMeter = 40.0;
  static const double _stepLengthMeters = 0.7;
  static const double _stepUnits = _stepLengthMeters * _mapUnitsPerMeter;
  
  // Orientation data
  List<double> _accelerometerValues = [0, 0, 0];
  List<double> _magnetometerValues = [0, 0, 0];

  NavigationProvider() {
    _voiceService.init();
    _voiceService.onSpeechStateChanged = () => notifyListeners();
  }


  bool get isNavigating => _isNavigating;
  bool get isIndoor => _isIndoor;
  bool get isLoadingRoute => _isLoadingRoute;
  
  NavigationPoint? get destination => _destination;
  EntryPoint? get targetEntryPoint => _targetEntryPoint;
  BuildingModel? get targetBuilding => _targetBuilding;

  NavigationRoute? get currentRoute => _currentRoute;
  List<LatLng> get remainingRouteCoordinates => 
      _remainingRouteCoordinates.isNotEmpty ? _remainingRouteCoordinates : (_currentRoute?.coordinates ?? []);
  String? get currentInstruction => _currentInstruction;
  /// Preview of the turn AFTER the approaching one (shown in "Then…" pill).
  String? get nextInstruction {
    if (_currentRoute == null) return null;
    final thenIdx = _currentInstructionIndex + 2;
    if (thenIdx >= _currentRoute!.instructions.length) return null;
    return _extractTurnAction(_currentRoute!.instructions[thenIdx].sign);
  }

  /// Shows the approaching turn icon when within 30 m, straight arrow otherwise.
  int get currentSign {
    if (_currentRoute == null || _currentRoute!.instructions.isEmpty) return 0;
    final nextIdx = _currentInstructionIndex + 1;
    if (nextIdx < _currentRoute!.instructions.length) {
      final dist = _distanceToNextStep ?? 999.0;
      if (dist <= 30.0) return _currentRoute!.instructions[nextIdx].sign;
    }
    return 0;
  }

  int? get nextSign {
    if (_currentRoute == null) return null;
    final thenIdx = _currentInstructionIndex + 2;
    if (thenIdx >= _currentRoute!.instructions.length) return null;
    return _currentRoute!.instructions[thenIdx].sign;
  }

  /// True when a turn is imminent (≤ 15 m away) — drives urgency UI.
  bool get isApproachingTurn =>
      _isNavigating &&
      _distanceToNextStep != null &&
      _distanceToNextStep! <= 15.0;

  double? get distanceToNextStep => _distanceToNextStep;
  double? get distanceToDestination => _distanceToDestination;
  int? get remainingTime {
    if (_distanceToDestination == null || _currentRoute == null || _currentRoute!.distance == 0) return null;
    // Simple proportional estimation: (remainingDist / totalDist) * totalTime
    double ratio = _distanceToDestination! / _currentRoute!.distance;
    return (ratio * (_currentRoute!.time / 60000)).ceil();
  }
  String? get arrivalTime {
    final remaining = remainingTime;
    if (remaining == null) return null;
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: remaining));
    final hour = arrival.hour > 12 ? arrival.hour - 12 : (arrival.hour == 0 ? 12 : arrival.hour);
    final minute = arrival.minute.toString().padLeft(2, '0');
    final period = arrival.hour >= 12 ? 'pm' : 'am';
    return "$hour:$minute $period";
  }
  String? get routeError => _routeError;
  List<LatLng> get nextSegmentCoordinates => _nextSegmentCoordinates;
  bool get isVoiceEnabled => _voiceService.isVoiceEnabled;
  bool get isSpeaking => _voiceService.isSpeaking;

  void toggleVoice() {
    _voiceService.toggleVoice();
    notifyListeners();
  }

  void speak(String text) {
    if (_voiceService.isVoiceEnabled) {
      _voiceService.speak(text);
    }
  }

  bool get isPdrEnabled => _isPdrEnabled;
  double? get indoorX => _indoorX;
  double? get indoorY => _indoorY;
  double get currentHeading => _currentHeading;
  bool get isMapRotationEnabled => _isMapRotationEnabled;
  String get currentIndoorInstruction => _currentIndoorInstruction;

  double get remainingIndoorDistance {
    if (_currentIndoorPath.isEmpty || _nextIndoorNodeIndex >= _currentIndoorPath.length || _indoorX == null || _indoorY == null) return 0;
    
    // Distance to next node
    final nextNode = _currentIndoorPath[_nextIndoorNodeIndex];
    double totalDist = math.sqrt(math.pow(_indoorX! - nextNode.x, 2) + math.pow(_indoorY! - nextNode.y, 2));
    
    // Distance through remaining nodes
    for (int i = _nextIndoorNodeIndex; i < _currentIndoorPath.length - 1; i++) {
      final p1 = _currentIndoorPath[i];
      final p2 = _currentIndoorPath[i + 1];
      totalDist += math.sqrt(math.pow(p1.x - p2.x, 2) + math.pow(p1.y - p2.y, 2));
    }
    
    return totalDist / _mapUnitsPerMeter;
  }

  ({double x1, double y1, double x2, double y2})? get nextIndoorSegment {
    if (_currentIndoorPath.isEmpty || _nextIndoorNodeIndex >= _currentIndoorPath.length || _indoorX == null || _indoorY == null) return null;
    
    return (
      x1: _indoorX!,
      y1: _indoorY!,
      x2: _currentIndoorPath[_nextIndoorNodeIndex].x,
      y2: _currentIndoorPath[_nextIndoorNodeIndex].y,
    );
  }

  void toggleMapRotation() {
    _isMapRotationEnabled = !_isMapRotationEnabled;
    notifyListeners();
  }

  Position? get currentPosition => _currentPosition;
  LatLng? get snappedPosition => _snappedPosition ?? (_currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : null);

  void setIndoorPath(List<GraphNode> path) {
    _currentIndoorPath = path;
    _nextIndoorNodeIndex = 1;
    _updateIndoorInstruction();
    notifyListeners();
  }

  void setIndoorPdrEnabled(bool enabled, {double? startX, double? startY, IndoorGraph? graph}) {
    _isPdrEnabled = enabled;
    if (enabled) {
      if (startX != null) _indoorX = startX;
      if (startY != null) _indoorY = startY;
      _currentIndoorGraph = graph;
      _currentSnappedEdge = null;
      _isPdrInitialized = false;
      _startPdrSensors();
    } else {
      _stopPdrSensors();
      _currentIndoorGraph = null;
    }
    notifyListeners();
  }

  void resetIndoorPosition() {
    if (_currentIndoorPath.isNotEmpty) {
      _indoorX = _currentIndoorPath.first.x;
      _indoorY = _currentIndoorPath.first.y;
      _nextIndoorNodeIndex = 1;
      _currentSnappedEdge = null;
      _updateIndoorInstruction();
      notifyListeners();
    }
  }

  void _recalculatePathProgress() {
    if (_currentIndoorPath.isEmpty || _indoorX == null || _indoorY == null) return;
    
    double minNodeDist = double.infinity;
    int bestIndex = 1;
    
    for (int i = 1; i < _currentIndoorPath.length; i++) {
      final node = _currentIndoorPath[i];
      double d = math.sqrt(math.pow(_indoorX! - node.x, 2) + math.pow(_indoorY! - node.y, 2));
      if (d < minNodeDist) {
        minNodeDist = d;
        bestIndex = i;
      }
    }
    _nextIndoorNodeIndex = bestIndex;
    _updateIndoorInstruction();
  }

  void _startPdrSensors() {
    _accelSubscription?.cancel();
    _magSubscription?.cancel();

    _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _handleAccelerometerEvent(event);
    });

    _magSubscription = magnetometerEvents.listen((MagnetometerEvent event) {
      _handleMagnetometerEvent(event);
    });
  }

  void _stopPdrSensors() {
    _accelSubscription?.cancel();
    _magSubscription?.cancel();
    _accelSubscription = null;
    _magSubscription = null;
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    _accelerometerValues = [event.x, event.y, event.z];
    
    // 1. Compute Raw Magnitude
    double rawMagnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    
    // 2. Apply Low-Pass Filter (Exponential Moving Average)
    // Smooths out high-frequency noise and sudden jolts
    _lastFilteredMagnitude = (_filterAlpha * rawMagnitude) + ((1.0 - _filterAlpha) * _lastFilteredMagnitude);
    
    // 3. Peak Detection with Threshold and Timing
    // Check if filtered magnitude falls within the walking impact range (11-13 m/s^2)
    if (_lastFilteredMagnitude >= _stepThresholdMin && _lastFilteredMagnitude <= _stepThresholdMax) {
      final now = DateTime.now();
      // Ensure minimum 300ms gap to avoid double-counting a single gait cycle
      if (_lastStepTime == null || now.difference(_lastStepTime!).inMilliseconds > 300) {
        _onStepDetected();
        _lastStepTime = now;
        debugPrint("Step detected! Magnitude: ${_lastFilteredMagnitude.toStringAsFixed(2)}");
      }
    }
  }

  void _handleMagnetometerEvent(MagnetometerEvent event) {
    _magnetometerValues = [event.x, event.y, event.z];
    _updateHeading();
  }

  void _updateHeading() {
    // 1. Tilt Compensation (Accelerometer + Magnetometer)
    // Ax, Ay, Az: Accelerometer (Gravity)
    // Mx, My, Mz: Magnetometer
    final double ax = _accelerometerValues[0];
    final double ay = _accelerometerValues[1];
    final double az = _accelerometerValues[2];
    final double mx = _magnetometerValues[0];
    final double my = _magnetometerValues[1];
    final double mz = _magnetometerValues[2];

    // Compute Cross Products to get world-oriented vectors
    // E = M x A (East vector)
    double ex = my * az - mz * ay;
    double ey = mz * ax - mx * az;
    double ez = mx * ay - my * ax;

    // N = A x E (North vector)
    double nx = ay * ez - az * ey;
    double ny = az * ex - ax * ez;
    double nz = ax * ey - ay * ex;

    // 2. Compute Azimuth
    // atan2(E.y, N.y) gives the heading in radians
    double newHeading = math.atan2(ey, ny);

    // 2.5 Direction Locking (Snap to Graph Edge)
    if (_isIndoor && _isPdrEnabled && _currentSnappedEdge != null && _currentIndoorGraph != null) {
      try {
        final edge = _currentSnappedEdge!;
        final nodeFrom = _currentIndoorGraph!.nodes.firstWhere((n) => n.id == edge.from);
        final nodeTo = _currentIndoorGraph!.nodes.firstWhere((n) => n.id == edge.to);
        
        // Calculate edge orientation
        double edgeAngle = math.atan2(nodeTo.y - nodeFrom.y, nodeTo.x - nodeFrom.x);
        double altAngle = edgeAngle + math.pi;
        
        // Normalize newHeading relative to edgeAngle
        double diff1 = (newHeading - edgeAngle + math.pi) % (2 * math.pi) - math.pi;
        double diff2 = (newHeading - altAngle + math.pi) % (2 * math.pi) - math.pi;
        
        // Snap to the closer direction
        if (diff1.abs() < diff2.abs()) {
          newHeading = edgeAngle;
        } else {
          newHeading = altAngle;
        }
      } catch (e) {
        debugPrint("Error locking direction: $e");
      }
    }

    // 2.8 PDR Initial Alignment (New)
    if (_isPdrEnabled && !_isPdrInitialized && _currentIndoorPath.length >= 2) {
      try {
        final p1 = _currentIndoorPath[0];
        final p2 = _currentIndoorPath[1];
        double routeAngle = math.atan2(p2.y - p1.y, p2.x - p1.x);
        _pdrHeadingOffset = routeAngle - newHeading;
        _isPdrInitialized = true;
        debugPrint("PDR Initialized. Route Angle: $routeAngle, Sensor Heading: $newHeading, Offset: $_pdrHeadingOffset");
      } catch (e) {
        debugPrint("Error initializing PDR alignment: $e");
      }
    }

    double adjustedHeading = newHeading + _pdrHeadingOffset;

    // 3. Smoothing with Wrap-around Handling
    // smoothHeading = prev + 0.1 * (new - prev)
    // We must ensure the difference (new - prev) is within [-pi, pi]
    double diff = adjustedHeading - _currentHeading;
    while (diff < -math.pi) diff += 2 * math.pi;
    while (diff > math.pi) diff -= 2 * math.pi;

    _currentHeading = _currentHeading + 0.1 * diff;

    // Normalize to [0, 2*pi]
    while (_currentHeading < 0) _currentHeading += 2 * math.pi;
    while (_currentHeading > 2 * math.pi) _currentHeading -= 2 * math.pi;

    notifyListeners();
  }

  void _onStepDetected() {
    if (!_isPdrEnabled || _indoorX == null || _indoorY == null) return;

    // 1. Calculate trial position
    double trialX = _indoorX! + _stepUnits * math.cos(_currentHeading);
    double trialY = _indoorY! + _stepUnits * math.sin(_currentHeading);

    // 2. Map Matching / Snapping
    if (_currentIndoorGraph != null) {
      final snapResult = _snapToGraphWithEdge(trialX, trialY);
      _indoorX = snapResult.point.x;
      _indoorY = snapResult.point.y;
      _currentSnappedEdge = snapResult.edge;
    } else {
      _indoorX = trialX;
      _indoorY = trialY;
    }

    // 3. Update Instructions based on distance to next node
    _checkIndoorProgress();

    notifyListeners();
  }

  void _checkIndoorProgress() {
    if (_currentIndoorPath.isEmpty || _nextIndoorNodeIndex >= _currentIndoorPath.length || _indoorX == null || _indoorY == null) return;

    final nextNode = _currentIndoorPath[_nextIndoorNodeIndex];
    double dist = math.sqrt(math.pow(_indoorX! - nextNode.x, 2) + math.pow(_indoorY! - nextNode.y, 2));

    // If within 2.5 meters (100 units), move to next target
    if (dist < 100.0) {
      // Junction Snapping: If very close to a node (< 1.5m / 60 units), snap exactly to it
      if (dist < 60.0) {
        _indoorX = nextNode.x;
        _indoorY = nextNode.y;
      }

      if (_nextIndoorNodeIndex < _currentIndoorPath.length - 1) {
        _nextIndoorNodeIndex++;
        _updateIndoorInstruction();
      } else {
        _currentIndoorInstruction = "You have arrived at your destination";
        // Final Snap: Force to destination node coordinates
        _indoorX = nextNode.x;
        _indoorY = nextNode.y;
      }
    } else {
      // Update "Go straight for X meters"
      double distMeters = dist / _mapUnitsPerMeter;
      if (!_currentIndoorInstruction.contains("Turn") && !_currentIndoorInstruction.contains("destination")) {
        _currentIndoorInstruction = "Go straight for ${distMeters.toStringAsFixed(0)} meters";
        
        // Speak if distance is a multiple of 10 for "Go straight"
        if (_voiceService.isVoiceEnabled && distMeters.round() % 10 == 0 && _lastSpokenInstruction != _currentIndoorInstruction) {
           _speakInstruction(_currentIndoorInstruction);
        }
      }
    }
  }

  void _speakInstruction(String text) {
    if (!_voiceService.isVoiceEnabled || text == _lastSpokenInstruction) return;
    _voiceService.speak(text);
    _lastSpokenInstruction = text;
  }

  void _updateIndoorInstruction() {
    if (_currentIndoorPath.isEmpty || _nextIndoorNodeIndex >= _currentIndoorPath.length) return;

    if (_nextIndoorNodeIndex == _currentIndoorPath.length - 1) {
      _currentIndoorInstruction = "Destination is ahead";
      return;
    }

    // Calculate angle between current edge and next edge
    final p1 = _currentIndoorPath[_nextIndoorNodeIndex - 1];
    final p2 = _currentIndoorPath[_nextIndoorNodeIndex];
    final p3 = _currentIndoorPath[_nextIndoorNodeIndex + 1];

    double angle1 = math.atan2(p2.y - p1.y, p2.x - p1.x);
    double angle2 = math.atan2(p3.y - p2.y, p3.x - p2.x);

    double diff = (angle2 - angle1 + math.pi) % (2 * math.pi) - math.pi;

    if (diff > math.pi / 4) {
      _currentIndoorInstruction = "Turn right at ${p2.label}";
    } else if (diff < -math.pi / 4) {
      _currentIndoorInstruction = "Turn left at ${p2.label}";
    } else {
      _currentIndoorInstruction = "Go straight towards ${p2.label}";
    }
    
    _speakInstruction(_currentIndoorInstruction);
  }

  math.Point<double> _snapToGraph(double x, double y) {
    return _snapToGraphWithEdge(x, y).point;
  }

  ({math.Point<double> point, GraphEdge? edge}) _snapToGraphWithEdge(double x, double y) {
    if (_currentIndoorGraph == null || _currentIndoorGraph!.edges.isEmpty) {
      return (point: math.Point(x, y), edge: null);
    }

    double minDistance = double.infinity;
    math.Point<double> bestPoint = math.Point(x, y);
    GraphEdge? bestEdge;

    // 1. Priority Snapping: Try edges on the current active route first
    if (_currentIndoorPath.isNotEmpty) {
      for (int i = 0; i < _currentIndoorPath.length - 1; i++) {
        final nodeFrom = _currentIndoorPath[i];
        final nodeTo = _currentIndoorPath[i + 1];

        final snapped = _projectPointToSegment(
          math.Point(x, y),
          math.Point(nodeFrom.x, nodeFrom.y),
          math.Point(nodeTo.x, nodeTo.y),
        );

        double dist = math.Point(x, y).distanceTo(snapped);
        if (dist < minDistance) {
          minDistance = dist;
          bestPoint = snapped;
          try {
            bestEdge = _currentIndoorGraph!.edges.firstWhere((e) =>
                (e.from == nodeFrom.id && e.to == nodeTo.id) ||
                (e.from == nodeTo.id && e.to == nodeFrom.id));
          } catch (_) {}
        }
      }

      // If we are close to the route (within ~5 meters), stick to it strictly
      if (minDistance < 200.0) {
        return (point: bestPoint, edge: bestEdge);
      }
    }

    // 2. Fallback Snapping: Check all graph edges if off-route or no path
    for (var edge in _currentIndoorGraph!.edges) {
      final nodeFrom = _currentIndoorGraph!.nodes.firstWhere((n) => n.id == edge.from);
      final nodeTo = _currentIndoorGraph!.nodes.firstWhere((n) => n.id == edge.to);

      final snapped = _projectPointToSegment(
        math.Point(x, y),
        math.Point(nodeFrom.x, nodeFrom.y),
        math.Point(nodeTo.x, nodeTo.y),
      );

      double dist = math.Point(x, y).distanceTo(snapped);
      if (dist < minDistance) {
        minDistance = dist;
        bestPoint = snapped;
        bestEdge = edge;
      }
    }

    // Constraint: Only snap if we are within a reasonable distance (e.g. 5 meters = 200 units)
    if (minDistance > 200.0) {
      // Find nearest node as fallback
      double minNodeDist = double.infinity;
      GraphNode? nearestNode;
      for (var node in _currentIndoorGraph!.nodes) {
        double d = math.sqrt(math.pow(x - node.x, 2) + math.pow(y - node.y, 2));
        if (d < minNodeDist) {
          minNodeDist = d;
          nearestNode = node;
        }
      }
      
      if (nearestNode != null && minNodeDist < 100.0) {
        return (point: math.Point(nearestNode.x, nearestNode.y), edge: null);
      }
      
      return (point: math.Point(_indoorX!, _indoorY!), edge: _currentSnappedEdge); 
    }

    return (point: bestPoint, edge: bestEdge);
  }

  math.Point<double> _projectPointToSegment(math.Point<double> p, math.Point<double> a, math.Point<double> b) {
    double l2 = a.distanceTo(b) * a.distanceTo(b);
    if (l2 == 0.0) return a;
    double t = ((p.x - a.x) * (b.x - a.x) + (p.y - a.y) * (b.y - a.y)) / l2;
    t = math.max(0.0, math.min(1.0, t));
    return math.Point(a.x + t * (b.x - a.x), a.y + t * (b.y - a.y));
  }

  Future<void> previewRoute(
      NavigationPoint destination, {
      BuildingModel? targetBuilding,
      EntryPoint? entryPoint,
  }) async {
    // 0. Robust Reset: Ensure any previous navigation or tracking is killed
    stopNavigation();
    
    _destination = destination;
    _targetBuilding = targetBuilding;
    _targetEntryPoint = entryPoint;
    _isNavigating = false;
    _isIndoor = false;
    _isLoadingRoute = true;
    _routeError = null;
    _remainingRouteCoordinates = [];
    _snappedPosition = null;
    notifyListeners();

    // 1. Warm up server (Anti-Cold Start)
    _currentInstruction = "Waking up server...";
    notifyListeners();
    await _graphHopperService.warmup();

    // 2. Get current location
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation);
    } catch (e) {
      debugPrint("Error getting location: $e");
      // Fallback to campus center for preview if location fails
      _currentPosition = Position(
        latitude: AppConstants.campusLat,
        longitude: AppConstants.campusLng,
        timestamp: DateTime.now(),
        accuracy: 100.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    if (_currentPosition != null) {
      // If user is far from campus, clamp to campus center for testing
      double distanceToCampus = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        AppConstants.campusLat,
        AppConstants.campusLng,
      );
      
      if (distanceToCampus > 2000) {
        _currentPosition = Position(
          latitude: AppConstants.campusLat,
          longitude: AppConstants.campusLng,
          timestamp: DateTime.now(),
          accuracy: 100.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      await _fetchRoute();
    }
    
    _isLoadingRoute = false;
    notifyListeners();
  }

  Future<void> _fetchRoute() async {
    if (_currentPosition == null || _destination == null) return;

    final start = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    // If we have a target building with multiple entry points, find the nearest by route distance.
    if (_targetBuilding != null && _targetBuilding!.entryPoints.isNotEmpty) {
      NavigationRoute? bestRoute;
      EntryPoint? bestEntryPoint;
      double minDistance = double.infinity;

      final futures = _targetBuilding!.entryPoints.map((ep) async {
        final end = LatLng(ep.latitude, ep.longitude);
        try {
          final route = await _graphHopperService.getRoute(start, end);
          return {'route': route, 'entryPoint': ep};
        } catch (e) {
          return null;
        }
      });

      final results = await Future.wait(futures);

      for (var res in results) {
        if (res != null && res['route'] != null) {
          final r = res['route'] as NavigationRoute;
          final ep = res['entryPoint'] as EntryPoint;
          if (r.distance < minDistance) {
            minDistance = r.distance;
            bestRoute = r;
            bestEntryPoint = ep;
          }
        }
      }

      if (bestRoute != null && bestEntryPoint != null) {
        _currentRoute = bestRoute;
        _targetEntryPoint = bestEntryPoint;
        _destination = NavigationPoint(lat: bestEntryPoint.latitude, lng: bestEntryPoint.longitude);

        _currentInstructionIndex = 0;
        if (_currentRoute!.instructions.isNotEmpty) {
          _currentInstruction = _currentRoute!.instructions.first.text;
        }
        _distanceToDestination = _currentRoute!.distance;
        _remainingRouteCoordinates = List.from(_currentRoute!.coordinates);
        _distanceToNextStep = _currentRoute!.instructions.isNotEmpty
            ? _currentRoute!.instructions[0].distance
            : null;
        return;
      }
    }

    final end = LatLng(_destination!.lat, _destination!.lng);
    
    try {
      final route = await _graphHopperService.getRoute(start, end);
      if (route != null) {
        _currentRoute = route;
        _currentInstructionIndex = 0;
        if (_currentRoute!.instructions.isNotEmpty) {
          _currentInstruction = _currentRoute!.instructions.first.text;
        }
        _distanceToDestination = _currentRoute!.distance;
        _remainingRouteCoordinates = List.from(_currentRoute!.coordinates);
        _distanceToNextStep = _currentRoute!.instructions.isNotEmpty 
            ? _currentRoute!.instructions[0].distance 
            : null;
      }
    } catch (e) {
      _routeError = e.toString();
      debugPrint('NavigationProvider Route Error: $_routeError');
    }
  }

  Future<void> startOutdoorNavigation() async {
    if (_destination == null || _currentRoute == null) return;
    
    _isNavigating = true;
    _isIndoor = false;
    _isRerouting = false;
    _remainingRouteCoordinates = List.from(_currentRoute!.coordinates);
    _snappedPosition = null;
    _positionBuffer.clear();
    _positionUpdateCount = 0;
    _deviationCount = 0;
    _currentInstructionIndex = 0;
    // Build distance-based initial instruction from the first segment's distance
    if (_currentRoute!.instructions.length > 1) {
      final firstSegDist = _currentRoute!.instructions[0].distance;
      _currentInstruction = firstSegDist > 0
          ? "Continue for ${firstSegDist.toStringAsFixed(0)} m"
          : "Head to destination";
    } else {
      _currentInstruction = "Head to destination";
    }
    _voiceService.resetLastSpoken();
    _voiceService.speak("Starting navigation. $_currentInstruction");
    
    notifyListeners();

    // Start live tracking
    _startLocationTracking();
  }

  void _startLocationTracking() {
    _positionStreamSubscription?.cancel();

    // Maximum frequency: 500ms interval, 0m distance filter (every sensor tick)
    // Platform-specific settings for maximum GPS polling rate
    final LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // No distance gate — emit every hardware update
        intervalDuration: const Duration(milliseconds: 500), // ~2 Hz from OS
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Navigation is in progress",
          notificationTitle: "NITC Campus Navigator",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // No distance gate
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // No distance gate
      );
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
            locationSettings: locationSettings)
        .listen((Position? position) {
      if (position != null) {
        _handlePositionUpdate(position);
      }
    });
  }
  void _handlePositionUpdate(Position position) {
    // 1. Accuracy Filtering: Ignore readings > 40 meters
    // Raised from 25m to accept more frequent fixes while still rejecting very bad readings
    if (position.accuracy > 40) {
      debugPrint("Ignoring low accuracy GPS reading: ${position.accuracy}m");
      return;
    }

    // 1.5 Performance Optimization: Throttling (Time + Distance)
    final now = DateTime.now();
    if (_lastUpdateTimestamp != null) {
      final timeDiff = now.difference(_lastUpdateTimestamp!).inMilliseconds;
      // Calculate distance from last raw position
      double distDiff = 0;
      if (_currentPosition != null) {
        distDiff = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          position.latitude,
          position.longitude,
        );
      }

      // Throttle: Ignore if < 150ms AND < 0.3m — allows ~6 updates/sec, accepts slow walking
      if (timeDiff < 150 && distDiff < 0.3) {
        return;
      }
    }
    _lastUpdateTimestamp = now;

    _currentPosition = position;
    
    // 2. Jitter Reduction: Process through Kalman Filter
    final LatLng filteredLatLng = _kalmanFilter.process(
      position.latitude,
      position.longitude,
      position.accuracy,
      position.timestamp.millisecondsSinceEpoch,
    );
    
    LatLng newLatLng = filteredLatLng;

    // Add to buffer for Map Matching
    _positionBuffer.add(position);
    if (_positionBuffer.length > 10) {
      _positionBuffer.removeAt(0);
    }
    _positionUpdateCount++;

    // 2. Smoothing: weighted average (0.5 * previous + 0.5 * current)
    // Higher alpha = more responsive to new positions (was 0.3, now 0.5)
    if (_snappedPosition != null) {
      newLatLng = NavigationUtils.smoothCoordinates(
        _snappedPosition!,
        newLatLng,
        alpha: 0.5,
      );
    }

    // 2.5 Map Matching: Trigger every 3 updates for more accurate route snapping
    if (_isNavigating && _positionUpdateCount % 3 == 0 && _positionBuffer.length >= 3) {
      _performMapMatching();
    }

    if (_currentRoute != null && _currentRoute!.coordinates.isNotEmpty) {
      // 3. Fallback/Manual Snapping: Stick to the active route polyline
      final snapResult = NavigationUtils.snapToPolyline(newLatLng, _currentRoute!.coordinates);
      final LatLng routeSnapped = snapResult['point'];
      final double distFromRoute = snapResult['distance'];
      final int segmentIndex = snapResult['index'];

      // Stick to path if within 20m of it
      if (distFromRoute < 20.0) {
        _snappedPosition = routeSnapped;
      } else {
        // Only use raw GPS/smoothed if we are far from the route
        _snappedPosition = newLatLng;
      }

      // 4. Deviation Detection (20m threshold for rerouting)
      if (distFromRoute > 20.0 && !_isRerouting) {
        _deviationCount++;
        debugPrint("Deviation detected ($_deviationCount/3): ${distFromRoute.toStringAsFixed(1)}m");
        
        if (_deviationCount >= 3) {
          final now = DateTime.now();
          if (_lastRerouteTime == null || now.difference(_lastRerouteTime!).inSeconds >= 5) {
            _triggerReroute();
          } else {
            debugPrint("Sustained deviation, but throttling reroute (last was < 5s ago)");
          }
        }
      } else if (distFromRoute <= 12.0) {
        // Reset deviation count if we are back on track
        _deviationCount = 0;
      }

    // 5. Progress Tracking (Update Remaining Route & Distance)
    _updateProgress(routeSnapped, segmentIndex);
    
    // 6. Update Turn-by-Turn Instructions
    _updateInstructions(routeSnapped, segmentIndex);
    
    // 7. Arrival Detection
    _checkArrival(position);
    } else {
      _snappedPosition = newLatLng;
    }

    notifyListeners();
  }

  void _updateProgress(LatLng snappedOnRoute, int segmentIndex) {
    if (_currentRoute == null) return;

    // Shrink the displayed route from the snapped point onwards
    _remainingRouteCoordinates = _currentRoute!.coordinates.sublist(segmentIndex);
    if (_remainingRouteCoordinates.isNotEmpty) {
        // Replace the first point of remaining route with the actual snapped point for visual accuracy
        _remainingRouteCoordinates[0] = snappedOnRoute;
    }

    // Calculate actual remaining distance along polyline
    _distanceToDestination = NavigationUtils.calculatePolylineDistance(_remainingRouteCoordinates);
  }

  void _updateInstructions(LatLng snapped, int segmentIndex) {
    if (_currentRoute == null || _currentRoute!.instructions.isEmpty) return;

    final instructions = _currentRoute!.instructions;

    // ── Last segment: no more turns ──────────────────────────────────────
    if (_currentInstructionIndex + 1 >= instructions.length) {
      _distanceToNextStep = _distanceToDestination;
      _currentInstruction = "Head to destination";
      _nextSegmentCoordinates = List.from(_remainingRouteCoordinates);
      return;
    }

    final nextInst = instructions[_currentInstructionIndex + 1];
    final int nextTurnNodeIdx = nextInst.interval[0]
        .clamp(0, _currentRoute!.coordinates.length - 1);

    // ── Compute precise distance to next turn along route polyline ────────
    if (nextTurnNodeIdx > segmentIndex + 1) {
      final legPoints = [
        snapped,
        ..._currentRoute!.coordinates
            .sublist(segmentIndex + 1, nextTurnNodeIdx + 1),
      ];
      _distanceToNextStep =
          NavigationUtils.calculatePolylineDistance(legPoints);
      _nextSegmentCoordinates = legPoints;
    } else {
      final nextTurnLatLng =
          _currentRoute!.coordinates[nextTurnNodeIdx];
      _distanceToNextStep =
          NavigationUtils.calculateDistance(snapped, nextTurnLatLng);
      _nextSegmentCoordinates = [snapped, nextTurnLatLng];
    }

    final double dist = _distanceToNextStep ?? 999.0;

    // ── Advance instruction when user arrives at turn node ────────────────
    if (dist < 8.0 || segmentIndex >= nextTurnNodeIdx) {
      _currentInstructionIndex++;
      _voiceService.resetLastSpoken();
      if (_currentInstructionIndex >= instructions.length) return;

      // Immediately show "Continue for Xm" using the new segment's distance
      if (_currentInstructionIndex + 1 < instructions.length) {
        final newSegDist =
            instructions[_currentInstructionIndex + 1].distance;
        _currentInstruction = newSegDist > 0
            ? "Continue for ${newSegDist.toStringAsFixed(0)} m"
            : "Head to destination";
        if (newSegDist > 30) {
          _voiceService
              .speak("Continue for ${newSegDist.toStringAsFixed(0)} meters");
        }
      } else {
        _currentInstruction = "Head to destination";
      }
      notifyListeners();
      return; // Fresh compute on next GPS tick
    }

    // ── Short-segment combining (back-to-back tight turns) ────────────────
    bool isCombined = false;
    String combinedText = "";
    if (dist <= 10.0 && _currentInstructionIndex + 2 < instructions.length) {
      final afterNextInst = instructions[_currentInstructionIndex + 2];
      if (afterNextInst.distance <= 15.0) {
        combinedText =
            "${_extractTurnAction(nextInst.sign)}, then immediately "
            "${_extractTurnAction(afterNextInst.sign).toLowerCase()}";
        isCombined = true;
      }
    }

    // ── Distance-adaptive instruction label ───────────────────────────────
    final String turnText = _extractTurnAction(nextInst.sign);

    if (dist <= 5.0) {
      _currentInstruction = isCombined ? combinedText : "Turn now";
    } else if (dist <= 15.0) {
      _currentInstruction = isCombined ? combinedText : turnText;
    } else if (dist <= 30.0) {
      _currentInstruction =
          "In ${dist.toStringAsFixed(0)} m, $turnText";
    } else {
      _currentInstruction = "Continue for ${dist.toStringAsFixed(0)} m";
    }

    // ── Tiered voice guidance ─────────────────────────────────────────────
    _voiceService.speakNavigationInstruction(
        turnText, dist, _currentInstructionIndex);
  }

  /// Maps a GraphHopper sign code to a clean, speakable action string.
  String _extractTurnAction(int sign) {
    switch (sign) {
      case -3:
        return "Turn sharp left";
      case -2:
        return "Turn left";
      case -1:
        return "Bear left";
      case 0:
        return "Continue straight";
      case 1:
        return "Bear right";
      case 2:
        return "Turn right";
      case 3:
        return "Turn sharp right";
      case 4:
        return "You have arrived";
      case 5:
        return "Make a U-turn";
      case 6:
        return "Continue straight";
      default:
        return "Continue";
    }
  }

  Future<void> _triggerReroute() async {
    if (_isRerouting || _currentPosition == null || _destination == null) return;
    
    debugPrint("Route deviation detected (>20m). Triggering reroute...");
    _isRerouting = true;
    _lastRerouteTime = DateTime.now();
    
    // Smooth transition: don't clear _currentRoute immediately to avoid flickering
    // but update the instruction and play voice alert
    _currentInstruction = "Rerouting...";
    _voiceService.speak("Rerouting. Please wait.");
    notifyListeners();

    try {
      // 1. Fetch new route from current position to original destination
      await _fetchRoute();
      
      if (_currentRoute != null) {
        // 2. Reset progress trackers for the new route
        _remainingRouteCoordinates = List.from(_currentRoute!.coordinates);
        _currentInstructionIndex = 0;
        _currentInstruction = _currentRoute!.instructions.isNotEmpty 
            ? _currentRoute!.instructions.first.text 
            : "Follow the new route";
        _deviationCount = 0; // Reset after successful reroute
        _voiceService.resetLastSpoken();
        debugPrint("Reroute successful. New instruction: $_currentInstruction");
      }
    } catch (e) {
      debugPrint("Rerouting failed: $e");
      _currentInstruction = "Still off route. Attempting to recover...";
    } finally {
      _isRerouting = false;
      notifyListeners(); // Final update to reflect new route on map
    }
  }

  Future<void> _performMapMatching() async {
    if (_positionBuffer.isEmpty) return;
    
    final matchedLatLng = await _graphHopperService.matchPoints(List.from(_positionBuffer));
    if (matchedLatLng != null) {
      debugPrint("Map Matching Result: Snapped from (${_currentPosition?.latitude}, ${_currentPosition?.longitude}) to (${matchedLatLng.latitude}, ${matchedLatLng.longitude})");
      _snappedPosition = matchedLatLng;
      notifyListeners();
    }
  }

  void _checkArrival(Position position) {
    if (_targetEntryPoint != null) {
      double distanceToEntry = NavigationUtils.calculateDistance(
        LatLng(position.latitude, position.longitude),
        LatLng(_targetEntryPoint!.latitude, _targetEntryPoint!.longitude),
      );

      if (distanceToEntry <= AppConstants.entryPointRadius && !_isIndoor) {
        _triggerIndoorArrival();
      }
    } else if (_destination != null) {
       double distanceToDest = NavigationUtils.calculateDistance(
        LatLng(position.latitude, position.longitude),
        LatLng(_destination!.lat, _destination!.lng),
      );
      
      if (distanceToDest <= 10.0 && !_isIndoor) {
          _currentInstruction = "You have arrived at your destination.";
          _voiceService.speak(_currentInstruction!);
      }
    }
  }

  void _triggerIndoorArrival() {
    _currentInstruction = 'You have arrived at ${_targetEntryPoint?.label ?? 'the entrance'}. Switch to indoor navigation.';
    _voiceService.speak(_currentInstruction!);
    switchToIndoorNavigation();
  }

  void switchToIndoorNavigation() {
    _isIndoor = true;
    _positionStreamSubscription?.cancel();
    _stopPdrSensors(); // Reset sensors when switching
    _isPdrEnabled = false;
    notifyListeners();
  }

  void stopNavigation() {
    _isNavigating = false;
    _isIndoor = false;
    _isLoadingRoute = false;
    _destination = null;
    _targetEntryPoint = null;
    _targetBuilding = null;
    _currentRoute = null;
    _currentInstruction = null;
    _currentInstructionIndex = 0;
    _distanceToDestination = null;
    _distanceToNextStep = null;
    _snappedPosition = null;
    _remainingRouteCoordinates = [];
    _nextSegmentCoordinates = [];
    _isRerouting = false;
    _isPdrEnabled = false;
    _routeError = null;
    
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _stopPdrSensors();
    
    _voiceService.stop(); // Immediately silence any ongoing speech instructions
    _voiceService.resetLastSpoken();
    
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
