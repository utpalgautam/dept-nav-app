import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/floor_model.dart';
import '../../models/location_model.dart';
import '../../services/firestore_service.dart';
import '../../services/astar_service.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import 'floor_transition_screen.dart';

class IndoorNavigationScreen extends StatefulWidget {
  final String buildingId;
  final String buildingName;
  final int floor;
  final String entryPointId;
  final String? destinationLocationId;

  const IndoorNavigationScreen({
    super.key,
    required this.buildingId,
    this.buildingName = 'Building',
    required this.floor,
    required this.entryPointId,
    this.destinationLocationId,
  });

  @override
  State<IndoorNavigationScreen> createState() => _IndoorNavigationScreenState();
}

class _IndoorNavigationScreenState extends State<IndoorNavigationScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  int _currentFloor = 0;
  FloorModel? _currentFloorData;
  IndoorGraph? _currentGraph;
  List<GraphNode> _currentPath = [];
  LocationModel? _destination;

  String _currentInstruction = 'Loading route...';
  String? _errorMessage;

  bool _isNavigatingToStairs = false;
  final bool _isDebugMode = false;

  // View toggles
  bool _is3DMode = true;
  bool _showLabels = false;

  // Map interactive state
  double _scale = 1.0;
  double _baseScale = 1.0;
  double _panX = 0.0;
  double _panY = 0.0;
  double _rotationZ = 0.05; // Initial slight rotation
  double _baseRotation = 0.05;
  final double _tiltAngle = -0.9; // Negative to tilt top away, bottom closer

  int _routeDistanceMeters = 0;

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.floor;
    _loadNavigationData();
  }

  @override
  void dispose() {
    // Ensure navigation is stopped when backing out of indoor screen
    Provider.of<NavigationProvider>(context, listen: false).stopNavigation();
    super.dispose();
  }

  Future<void> _loadNavigationData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.destinationLocationId != null) {
        _destination =
            await _firestoreService.getLocation(widget.destinationLocationId!);
      }

      _currentFloorData =
          await _firestoreService.getFloorMap(widget.buildingId, _currentFloor);

      _currentGraph = await _firestoreService.getIndoorGraph(
          widget.buildingId, _currentFloor);

      if (_currentGraph == null) {
        _errorMessage = 'Indoor navigation unavailable for this floor.';
        _currentInstruction = _errorMessage!;
      } else {
        await _calculateRoute();
      }
    } catch (e, stack) {
      debugPrint('Error loading indoor nav data: $e');
      debugPrint('Stack trace: $stack');
      _errorMessage = 'Failed to load navigation data: $e';
      _currentInstruction = 'Failed to load navigation data.';
    }

    if (mounted) {
      setState(() => _isLoading = false);
      // Initial voice announcement
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          context.read<NavigationProvider>().speak(_currentInstruction);
        }
      });
    }
  }

  Future<void> _calculateRoute() async {
    _currentPath = [];
    if (_destination == null) {
      _currentInstruction = 'Destination not found.';
      return;
    }

    if (_currentGraph == null) {
      _currentInstruction = 'Indoor navigation unavailable for this floor.';
      return;
    }

    final int targetFloor = _destination?.floor ?? 0;
    final IndoorGraph graph = _currentGraph!;
    final String entryLabel = widget.entryPointId;
    final String roomLabel = _destination!.roomNumber ?? _destination!.name;

    if (_currentFloor != targetFloor) {
      _isNavigatingToStairs = true;
      _currentPath = AStarService.findPath(graph, entryLabel, "Stairs");

      if (_currentPath.isEmpty) {
        _currentPath = AStarService.findPath(graph, "Stairs", "Stairs");
        if (_currentPath.isEmpty) {
          _currentInstruction = 'Route to stairs not found.';
        } else {
          _currentInstruction = 'Route from $entryLabel to stairs not found.';
        }
      } else {
        _currentInstruction = 'Follow the route to Stairs';
      }
    } else {
      _isNavigatingToStairs = false;
      String startLabel = entryLabel;
      if (_currentFloor != widget.floor) {
        startLabel = "Stairs";
      }

      _currentPath = AStarService.findPath(graph, startLabel, roomLabel);

      if (_currentPath.isEmpty && startLabel == "Stairs") {
        _currentPath = AStarService.findPath(graph, entryLabel, roomLabel);
      }

      if (_currentPath.isEmpty) {
        _currentInstruction = 'Route to $roomLabel not found.';
      } else {
        _currentInstruction = 'Follow the route to $roomLabel';
      }
    }

    _calculateRouteDistance();
  }

  void _calculateRouteDistance() {
    if (_currentPath.isEmpty || _currentGraph == null) {
      _routeDistanceMeters = 0;
      return;
    }

    double totalWeight = 0.0;
    for (int i = 0; i < _currentPath.length - 1; i++) {
      final nodeA = _currentPath[i];
      final nodeB = _currentPath[i + 1];

      try {
        final edge = _currentGraph!.edges.firstWhere((e) =>
            (e.from == nodeA.id && e.to == nodeB.id) ||
            (e.from == nodeB.id && e.to == nodeA.id));
        totalWeight += edge.weight;
      } catch (_) {}
    }

    _routeDistanceMeters = (totalWeight / 40).round();
  }

  void _onReachedWaypoint() {
    if (_isNavigatingToStairs) {
      _showStairDialog();
    } else {
      _showArrivalDialog();
    }
  }

  void _showStairDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FloorTransitionScreen(
          currentFloor: _currentFloor,
          targetFloor: _destination?.floor ?? 0,
          subInstruction: _currentInstruction.contains('Stairs') ? 'Straight 50m' : _currentInstruction,
          onConfirm: () {
            _switchFloor(_destination?.floor ?? 0);
          },
        ),
      ),
    );
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Destination Reached',
            style: TextStyle(color: Colors.white)),
        content: Text('You have arrived at ${_destination?.name}.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<NavigationProvider>(context, listen: false)
                  .stopNavigation();
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close nav screen
            },
            child: const Text('Finish', style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
    );
  }

  void _switchFloor(int newFloor) {
    setState(() {
      _currentFloor = newFloor;
    });
    _loadNavigationData();
  }

  String _getProcessedSvg() {
    if (_currentFloorData == null &&
        (_currentFloorData?.svgMapData == null &&
            _currentFloorData?.svgMapUrl == null)) {
      return '';
    }
    if (_currentFloorData == null) return '';

    String svg = _currentFloorData!.svgMapData ?? '';
    if (svg.isEmpty) return '';

    final vb = _currentGraph?.viewBox ?? [0.0, 0.0, 800.0, 600.0];
    final double mapWidth = (vb.length > 2 && vb[2] > 0) ? vb[2] : 800.0;
    final double mapHeight = (vb.length > 3 && vb[3] > 0) ? vb[3] : 600.0;
    String viewBoxStr =
        '${vb.isNotEmpty ? vb[0] : 0.0} ${vb.length > 1 ? vb[1] : 0.0} $mapWidth $mapHeight';

    svg = svg.replaceFirst(RegExp(r'<svg[^>]*>'),
        '<svg viewBox="$viewBoxStr" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg">');

    StringBuffer overlays = StringBuffer();

    // Add Route with arrows
    if (_currentPath.isNotEmpty) {
      String points = _currentPath.map((p) => '${p.x},${p.y}').join(' ');

      overlays.write(
          '<polyline points="$points" stroke="#bfdbfe" stroke-width="24" fill="none" stroke-linecap="round" stroke-linejoin="round" />');

      double arrowSpacing = 20.0;
      double arrowSize = 8.0;

      for (int i = 0; i < _currentPath.length - 1; i++) {
        final p1 = _currentPath[i];
        final p2 = _currentPath[i + 1];
        double dx = p2.x - p1.x;
        double dy = p2.y - p1.y;
        double dist = math.sqrt(dx * dx + dy * dy);
        double angle = math.atan2(dy, dx);

        if (dist > arrowSpacing) {
          int count = (dist / arrowSpacing).floor();
          for (int j = 1; j <= count; j++) {
            double fraction = (j * arrowSpacing) / dist;
            double cx = p1.x + dx * fraction;
            double cy = p1.y + dy * fraction;

            double x1 = cx - math.cos(angle - math.pi / 6) * arrowSize;
            double y1 = cy - math.sin(angle - math.pi / 6) * arrowSize;
            double x2 = cx - math.cos(angle + math.pi / 6) * arrowSize;
            double y2 = cy - math.sin(angle + math.pi / 6) * arrowSize;

            overlays.write(
                '<polyline points="$x1,$y1 $cx,$cy $x2,$y2" stroke="#2563eb" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round" />');
          }
        }
      }

      // Highlight next segment if PDR is enabled
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      if (navProvider.isPdrEnabled) {
        final segment = navProvider.nextIndoorSegment;
        if (segment != null) {
          overlays.write(
              '<polyline points="${segment.x1},${segment.y1} ${segment.x2},${segment.y2}" stroke="#2563eb" stroke-width="24" fill="none" stroke_linecap="round" stroke_linejoin="round" />');
          // Add a white core for better visibility
          overlays.write(
              '<polyline points="${segment.x1},${segment.y1} ${segment.x2},${segment.y2}" stroke="#93c5fd" stroke-width="8" fill="none" stroke_linecap="round" stroke_linejoin="round" />');
        }
      }

      // Start Marker (only if PDR is off)
      final start = _currentPath.first;
      if (!navProvider.isPdrEnabled) {
        overlays.write(
            '<circle cx="${start.x}" cy="${start.y}" r="16" fill="#bfdbfe" fill-opacity="0.8" />');
        overlays.write(
            '<circle cx="${start.x}" cy="${start.y}" r="8" fill="#2563eb" />');
      }
    }

    // User marker logic moved to _buildUserMarker() (Flutter widget for smooth animation)

    // Debug Nodes
    if (_isDebugMode && _currentGraph != null) {
      for (var node in _currentGraph!.nodes) {
        overlays.write(
            '<circle cx="${node.x}" cy="${node.y}" r="4" fill="red" fill-opacity="0.6" />');
      }
    }

    return svg.replaceFirst('</svg>', '${overlays.toString()}</svg>');
  }

  /// 2D label overlays — placed inside the Transform stack (correct in 2D mode)
  List<Widget> _build2DLabelOverlays(
      double mapWidth, double mapHeight, double w, double h) {
    if (_currentGraph == null) return [];
    final labelNodes = _currentGraph!.nodes
        .where((n) => n.type != 'hallway' && n.label.isNotEmpty)
        .toList();
    return labelNodes.map((node) {
      final double left = (node.x / mapWidth) * w;
      final double top = (node.y / mapHeight) * h;
      return Positioned(
        left: left - 3,
        top: top - 3,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _nodeColor(node.type),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1)),
                ],
              ),
            ),
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black12, width: 0.5),
              ),
              child: Text(
                node.label,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// 3D labels — placed OUTSIDE the Transform in screen space.
  /// We project each node's map coords through the same Matrix4 used by the
  /// Transform widget (with perspective division) to get the exact screen
  /// position. Labels placed here are always upright and always on the node.
  List<Widget> _build3DScreenSpaceLabels({
    required double screenW,
    required double screenH,
    required double mapWidth,
    required double mapHeight,
    required double displayW,
    required double displayH,
    required double mapLeft,
    required double mapTop,
    required Matrix4 transform,
  }) {
    if (_currentGraph == null) return [];
    final labelNodes = _currentGraph!.nodes
        .where((n) => n.type != 'hallway' && n.label.isNotEmpty)
        .toList();

    final cx = screenW / 2.0;
    final cy = screenH / 2.0;
    final s = transform.storage; // column-major Float64List

    return labelNodes.map((node) {
      // Node position in container space
      final double nx = mapLeft + (node.x / mapWidth) * displayW;
      final double ny = mapTop + (node.y / mapHeight) * displayH;
      // Shift to transform pivot (center of screen)
      final double px = nx - cx;
      final double py = ny - cy;
      // Apply matrix (z=0, w=1) — column-major indexing
      final double xp = s[0] * px + s[4] * py + s[12];
      final double yp = s[1] * px + s[5] * py + s[13];
      final double wp = s[3] * px + s[7] * py + s[15];
      final double sx = (wp == 0 ? xp : xp / wp) + cx;
      final double sy = (wp == 0 ? yp : yp / wp) + cy;

      // Stem tip is at (sx, sy). Box + stem sit above it.
      const double boxH = 22.0;
      const double stemH = 5.0;
      const double dotR = 3.5;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Blue node dot at exact projected position
          Positioned(
            left: sx - dotR,
            top: sy - dotR,
            child: Container(
              width: dotR * 2,
              height: dotR * 2,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 3,
                  )
                ],
              ),
            ),
          ),
          // Callout Box
          Positioned(
            left: sx,
            top: sy - stemH - 2, 
            child: FractionalTranslation(
              translation: const Offset(-0.5, -1.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      node.label,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Triangle stem
                  CustomPaint(
                    size: const Size(8, 5),
                    painter: _TrianglePainter(),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  Color _nodeColor(String type) {
    switch (type) {
      case 'room':
        return Colors.blue.shade600;
      case 'stairs':
        return Colors.orange.shade600;
      case 'entrance':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          Provider.of<NavigationProvider>(context, listen: false).stopNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blue))
            : Stack(
                children: [
                  Positioned.fill(
                    child: _buildMapView(),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            Padding(
                              padding: const EdgeInsets.only(left: 16), // Aligns with the icon start in the header
                              child: _buildNextStepBox(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Toggle buttons: top-right, below the header
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 140,
                    right: 20,
                    child: _buildToggleButtons(),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomPanel(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNextStepBox() {
    if (!_isNavigatingToStairs) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Next Change floor",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.swap_calls_rounded, color: Colors.white, size: 14),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<NavigationProvider>(
      builder: (context, navProv, child) {
        String mainInstruction = navProv.isPdrEnabled 
            ? navProv.currentIndoorInstruction 
            : _currentInstruction;
        
        // Extract distance if possible for sub-instruction
        String subInstruction = "Follow the blue path";
        if (mainInstruction.contains("meters")) {
           final match = RegExp(r'(\d+)\s+meters').firstMatch(mainInstruction);
           if (match != null) {
             subInstruction = "Straight ${match.group(1)}m";
           }
        } else if (_isNavigatingToStairs) {
            subInstruction = ""; // Already shown in main instruction
        } else if (_destination != null) {
            // No need to repeat "Follow route to [Target]" in sub-text
            subInstruction = ""; 
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mainInstruction,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                     if (subInstruction.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subInstruction,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                     ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  shape: BoxShape.circle,
                  boxShadow: navProv.isSpeaking
                      ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ]
                      : [],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    navProv.toggleVoice();
                    navProv.speak(navProv.isVoiceEnabled ? "Voice navigation enabled" : "Voice navigation disabled");
                  },
                  icon: Icon(
                    Icons.mic_rounded,
                    color: navProv.isSpeaking ? Colors.blue : Colors.black,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleButtons() {
    return Consumer<NavigationProvider>(
      builder: (context, navProv, child) {
        return Column(
          children: [
            _buildPremiumIconButton(
              icon: _is3DMode ? Icons.view_in_ar_rounded : Icons.layers_outlined,
              isActive: _is3DMode,
              onTap: () {
                setState(() {
                  _is3DMode = !_is3DMode;
                  if (!_is3DMode) {
                    _rotationZ = 0.0;
                    _baseRotation = 0.0;
                  } else {
                    _rotationZ = 0.05;
                    _baseRotation = 0.05;
                  }
                });
                navProv.speak(_is3DMode ? "3D perspective enabled" : "2D overview enabled");
              },
            ),
            const SizedBox(height: 12),
            _buildPremiumIconButton(
              icon: _showLabels ? Icons.chat_bubble_rounded : Icons.speaker_notes_off_rounded,
              isActive: _showLabels,
              onTap: () {
                setState(() => _showLabels = !_showLabels);
                navProv.speak(_showLabels ? "Labels visible" : "Labels hidden");
              },
            ),
            const SizedBox(height: 12),
            _buildPremiumIconButton(
              icon: Icons.directions_walk_rounded,
              isActive: navProv.isPdrEnabled,
              onTap: () {
                if (!navProv.isPdrEnabled) {
                  if (_currentPath.isNotEmpty) {
                    navProv.setIndoorPdrEnabled(true, 
                      startX: _currentPath.first.x, 
                      startY: _currentPath.first.y,
                      graph: _currentGraph,
                    );
                    navProv.setIndoorPath(_currentPath);
                  }
                } else {
                  navProv.setIndoorPdrEnabled(false);
                }
                navProv.speak(navProv.isPdrEnabled ? "P.D.R. mode enabled" : "P.D.R. mode disabled");
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumIconButton({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? null : Border.all(color: Colors.black12, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.black,
          size: 22,
        ),
      ),
    );
  }


  Widget _buildMapView() {
    final processedSvg = _getProcessedSvg();
    if (processedSvg.isEmpty) {
      return Center(
        child: Text(
          'Map data missing for Floor $_currentFloor',
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    final vb = _currentGraph?.viewBox ?? [0.0, 0.0, 800.0, 600.0];
    final double mapWidth = (vb.length > 2 && vb[2] > 0) ? vb[2] : 800.0;
    final double mapHeight = (vb.length > 3 && vb[3] > 0) ? vb[3] : 600.0;

    return LayoutBuilder(builder: (context, outerConstraints) {
      final double screenW = outerConstraints.maxWidth;
      final double screenH = outerConstraints.maxHeight;

      // Compute where the AspectRatio widget renders within screenW x screenH
      final double ratio = mapWidth / mapHeight;
      final double displayW, displayH, mapLeft, mapTop;
      if (screenW / screenH >= ratio) {
        displayH = screenH;
        displayW = displayH * ratio;
      } else {
        displayW = screenW;
        displayH = displayW / ratio;
      }
      mapLeft = (screenW - displayW) / 2.0;
      mapTop = (screenH - displayH) / 2.0;

      return Consumer<NavigationProvider>(
        builder: (context, navProvider, child) {
          double targetRotation = _rotationZ;
          if (navProvider.isMapRotationEnabled) {
            // Target rotation for "Heading Up"
            targetRotation = -navProvider.currentHeading - math.pi / 2;
          }

          return GestureDetector(
            onScaleStart: (details) {
              _baseScale = _scale;
              _baseRotation = _rotationZ;
            },
            onScaleUpdate: (details) {
              if (navProvider.isMapRotationEnabled) return;
              setState(() {
                _panX += details.focalPointDelta.dx;
                _panY += details.focalPointDelta.dy;
                _scale = (_baseScale * details.scale).clamp(0.5, 6.0);
                _rotationZ = _baseRotation + details.rotation;
              });
            },
            child: ClipRRect(
              child: Container(
                color: Colors.white,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: targetRotation, end: targetRotation),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        builder: (context, animRot, child) {
                          final Matrix4 currentTransform = Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..translate(_panX, _panY);
                          
                          if (_is3DMode) {
                            currentTransform
                              ..rotateX(_tiltAngle)
                              ..scale(_scale)
                              ..rotateZ(animRot);
                          } else {
                            currentTransform
                              ..scale(_scale)
                              ..rotateZ(animRot);
                          }

                          return Transform(
                            alignment: Alignment.center,
                            transform: currentTransform,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // ── Dot-Grid Background (Whiteboard style) ──
                                OverflowBox(
                                  minWidth: 5000,
                                  maxWidth: 5000,
                                  minHeight: 5000,
                                  maxHeight: 5000,
                                  child: CustomPaint(
                                    size: const Size(5000, 5000),
                                    painter: _DotGridPainter(),
                                  ),
                                ),
                                // ── The Map ────────────────────────────────
                                Center(
                                  child: AspectRatio(
                                    aspectRatio: mapWidth / mapHeight,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final double w = constraints.maxWidth;
                                        final double h = constraints.maxHeight;
                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            SvgPicture.string(
                                              processedSvg,
                                              fit: BoxFit.contain,
                                            ),
                                            if (_currentPath.isNotEmpty)
                                              Positioned(
                                                left: (_currentPath.last.x / mapWidth) * w - 24,
                                                top: (_currentPath.last.y / mapHeight) * h - 48,
                                                child: Transform(
                                                  alignment: Alignment.bottomCenter,
                                                  transform: Matrix4.identity()
                                                    ..rotateZ(-animRot)
                                                    ..rotateX(_is3DMode ? -_tiltAngle : 0),
                                                  child: const Icon(
                                                    Icons.location_on,
                                                    color: Colors.black,
                                                    size: 48,
                                                  ),
                                                ),
                                              ),
                                            // NEW: Animated User Marker
                                            _buildUserMarker(w, h, mapWidth, mapHeight, animRot),
                                            if (_showLabels && !_is3DMode)
                                              ..._build2DLabelOverlays(mapWidth, mapHeight, w, h),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (_showLabels && _is3DMode)
                      ..._build3DScreenSpaceLabels(
                        screenW: screenW,
                        screenH: screenH,
                        mapWidth: mapWidth,
                        mapHeight: mapHeight,
                        displayW: displayW,
                        displayH: displayH,
                        mapLeft: mapLeft,
                        mapTop: mapTop,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..translate(_panX, _panY)
                          ..rotateX(_tiltAngle)
                          ..scale(_scale)
                          ..rotateZ(targetRotation),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildUserMarker(double w, double h, double mapWidth, double mapHeight, double mapRotation) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        if (!navProvider.isPdrEnabled || navProvider.indoorX == null || navProvider.indoorY == null) {
          return const SizedBox.shrink();
        }

        final double x = navProvider.indoorX!;
        final double y = navProvider.indoorY!;
        final double heading = navProvider.currentHeading;

        return TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(begin: Offset(x, y), end: Offset(x, y)),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, pos, child) {
            return Positioned(
              left: (pos.dx / mapWidth) * w - 30,
              top: (pos.dy / mapHeight) * h - 30,
              child: SizedBox(
                width: 60,
                height: 60,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: heading, end: heading),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedHeading, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Accuracy Aura
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF3B82F6).withOpacity(0.12),
                          ),
                        ),
                        // Direction Beam
                        Transform.rotate(
                          angle: animatedHeading + math.pi / 2,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF3B82F6).withOpacity(0.4),
                                  Colors.transparent,
                                ],
                                stops: const [0.2, 1.0],
                                center: const Alignment(0, -0.2), // Shift gradient towards top
                              ),
                            ),
                          ),
                        ),
                        // Inner White Dot
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ),
                        // Direction Arrow Painter
                        Transform.rotate(
                          angle: animatedHeading + math.pi / 2,
                          child: CustomPaint(
                            size: const Size(20, 20),
                            painter: _ArrowPainter(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPdrStatusBox() {
    return Consumer<NavigationProvider>(
      builder: (context, navProv, child) {
        if (!navProv.isPdrEnabled) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 12),
                  const SizedBox(width: 6),
                  const Text("PDR Enabled", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                   const Icon(Icons.sensors_rounded, color: Colors.white, size: 12),
                   const SizedBox(width: 6),
                   const Text("Live Tracking", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomPanel() {
    return Consumer<NavigationProvider>(
      builder: (context, navProv, child) {
        final distance = navProv.isPdrEnabled 
            ? navProv.remainingIndoorDistance 
            : _routeDistanceMeters.toDouble();
        
        // Estimation: 1.2m/s walking speed
        final int timeEstimate = (distance / 1.2 / 60).ceil();
        final now = DateTime.now();
        final arrival = now.add(Duration(minutes: timeEstimate));
        final arrivalTimeStr = "${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}";

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPdrStatusBox(),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // Drag handle
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Exit Button
                      GestureDetector(
                        onTap: () {
                          navProv.stopNavigation();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        ),
                      ),

                      // Center Metrics
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                Text(
                                  "$timeEstimate min",
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.directions_walk_rounded, 
                                  color: Colors.black87, size: 24),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${distance.toStringAsFixed(0)} m • $arrivalTimeStr",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withOpacity(0.5),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Confirm Button
                      GestureDetector(
                        onTap: _onReachedWaypoint,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB).withOpacity(0.6) // Light gray dots
      ..strokeWidth = 1.0;

    const double spacing = 32.0;
    
    // Efficiently draw the grid
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width * 0.8, size.height * 0.8)
      ..lineTo(size.width / 2, size.height * 0.6)
      ..lineTo(size.width * 0.2, size.height * 0.8)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the small downward-pointing triangle (comment box stem)
class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => false;
}

/// Custom painter that draws a dashed rounded-rectangle border
class _DashedRoundedBorderPainter extends CustomPainter {
  final Color color;
  final double dash;
  final double gap;
  final double radius;
  final double strokeWidth;

  _DashedRoundedBorderPainter({
    this.color = Colors.black38,
    this.dash = 2.5,
    this.gap = 2.5,
    this.radius = 6.0,
    this.strokeWidth = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      bool drawing = true;
      while (distance < metric.length) {
        final segEnd = (distance + (drawing ? dash : gap))
            .clamp(0.0, metric.length);
        if (drawing) {
          canvas.drawPath(
              metric.extractPath(distance, segEnd), paint);
        }
        distance = segEnd;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter old) => false;
}
