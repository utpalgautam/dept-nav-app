import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/building_model.dart';
import '../../models/floor_model.dart';
import '../../services/astar_service.dart';
import '../../services/firestore_service.dart';

class IndoorRouteViewScreen extends StatefulWidget {
  final BuildingModel buildingModel;
  final int floorNo;
  final IndoorGraph graph;
  final GraphNode startNode;
  final GraphNode endNode;

  const IndoorRouteViewScreen({
    super.key,
    required this.buildingModel,
    required this.floorNo,
    required this.graph,
    required this.startNode,
    required this.endNode,
  });

  @override
  State<IndoorRouteViewScreen> createState() => _IndoorRouteViewScreenState();
}

class _IndoorRouteViewScreenState extends State<IndoorRouteViewScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  FloorModel? _floorData;
  List<GraphNode> _currentPath = [];
  String _errorMessage = '';

  // 3D Map interactive state
  double _scale = 1.0;
  double _baseScale = 1.0;
  double _panX = 0.0;
  double _panY = 0.0;
  double _rotationZ = 0.05;
  double _baseRotation = 0.05;
  final double _tiltAngle = -0.9;

  int _routeDistanceMeters = 0;

  @override
  void initState() {
    super.initState();
    _loadDataAndComputeRoute();
  }

  Future<void> _loadDataAndComputeRoute() async {
    try {
      // 1. Compute Path immediately since we already have the graph
      final path = AStarService.findPath(
          widget.graph, widget.startNode.id, widget.endNode.id);

      if (path.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'No route found between selected nodes.';
            _isLoading = false;
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_errorMessage)));
        }
        return;
      }
      _currentPath = path;
      debugPrint(
          'A* Computed Route nodes: ${_currentPath.map((n) => n.id).toList()}');

      _calculateRouteDistance();

      // 2. Fetch Floor Map Data for rendering SVG
      final floorData = await _firestoreService.getFloorMap(
          widget.buildingModel.id, widget.floorNo);

      if (mounted) {
        setState(() {
          _floorData = floorData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading floor map: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load floor map data.';
          _isLoading = false;
        });
      }
    }
  }

  void _calculateRouteDistance() {
    if (_currentPath.isEmpty) {
      _routeDistanceMeters = 0;
      return;
    }

    double totalWeight = 0.0;
    for (int i = 0; i < _currentPath.length - 1; i++) {
      final nodeA = _currentPath[i];
      final nodeB = _currentPath[i + 1];
      
      try {
        final edge = widget.graph.edges.firstWhere(
          (e) => (e.from == nodeA.id && e.to == nodeB.id) || 
                 (e.from == nodeB.id && e.to == nodeA.id)
        );
        totalWeight += edge.weight;
      } catch (_) {}
    }

    _routeDistanceMeters = (totalWeight / 40).round();
  }

  @override
  Widget build(BuildContext context) {
    String floorName =
        widget.floorNo == 0 ? 'Ground Floor' : 'Floor ${widget.floorNo}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildInteractiveMap(),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: _buildHeaderWidget(floorName),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomControlsWidget(),
                  )
                ],
              ),
            ),
    );
  }

  String _getProcessedSvg() {
    if (_floorData == null || (_floorData!.svgMapData == null && _floorData!.svgMapUrl == null)) {
      return '';
    }

    String svg = _floorData!.svgMapData ?? '';
    if (svg.isEmpty) return '';

    final vb = widget.graph.viewBox ?? [0.0, 0.0, 800.0, 600.0];
    final double mapWidth = (vb.length > 2 && vb[2] > 0) ? vb[2] : 800.0;
    final double mapHeight = (vb.length > 3 && vb[3] > 0) ? vb[3] : 600.0;
    String viewBoxStr = '${vb.isNotEmpty ? vb[0] : 0.0} ${vb.length > 1 ? vb[1] : 0.0} $mapWidth $mapHeight';

    // Ensure svg tag has the correct viewBox and remove width/height to let it scale in container
    svg = svg.replaceFirst(RegExp(r'<svg[^>]*>'), '<svg viewBox="$viewBoxStr" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg">');

    StringBuffer overlays = StringBuffer();

    // Add Route
    if (_currentPath.isNotEmpty) {
      String points = _currentPath.map((p) => '${p.x},${p.y}').join(' ');
      
      // Light blue base line (much thicker to match reference)
      overlays.write('<polyline points="$points" stroke="#bfdbfe" stroke-width="24" fill="none" stroke-linecap="round" stroke-linejoin="round" />');

      // Explicitly draw chevrons instead of using SVG markers safely
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
            
            overlays.write('<polyline points="$x1,$y1 $cx,$cy $x2,$y2" stroke="#2563eb" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round" />');
          }
        }
      }
      
      // Destination pin is now handled as a Flutter widget overlay

      // Start Marker (Light Blue Outer Circle, Dark Blue Inner Circle)
      final start = _currentPath.first;
      overlays.write('<circle cx="${start.x}" cy="${start.y}" r="16" fill="#bfdbfe" fill-opacity="0.8" />');
      overlays.write('<circle cx="${start.x}" cy="${start.y}" r="8" fill="#2563eb" />');
    }

    // Inject before closing svg tag
    return svg.replaceFirst('</svg>', '${overlays.toString()}</svg>');
  }

  Widget _buildInteractiveMap() {
    if (_errorMessage.isNotEmpty && _floorData == null) {
      return Center(child: Text(_errorMessage));
    }

    final processedSvg = _getProcessedSvg();
    debugPrint('Processed SVG length: ${processedSvg.length}');
    if (processedSvg.length < 500) {
      debugPrint('Processed SVG content: $processedSvg');
    } else {
      debugPrint('Processed SVG start: ${processedSvg.substring(0, 200)}');
      debugPrint('Processed SVG end: ${processedSvg.substring(processedSvg.length - 200)}');
    }
    if (processedSvg.isEmpty) {
      return Center(
        child: Text('Map for Floor ${widget.floorNo} not available'),
      );
    }

    final vb = widget.graph.viewBox ?? [0.0, 0.0, 800.0, 600.0];
    final double mapWidth = (vb.length > 2 && vb[2] > 0) ? vb[2] : 800.0;
    final double mapHeight = (vb.length > 3 && vb[3] > 0) ? vb[3] : 600.0;

    return GestureDetector(
      onScaleStart: (details) {
        _baseScale = _scale;
        _baseRotation = _rotationZ;
      },
      onScaleUpdate: (details) {
        setState(() {
          _panX += details.focalPointDelta.dx;
          _panY += details.focalPointDelta.dy;
          _scale = (_baseScale * details.scale).clamp(0.5, 6.0);
          _rotationZ = _baseRotation + details.rotation;
        });
      },
      child: ClipRRect(
        child: Container(
          color: const Color(0xFFF5F5F5),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..translate(_panX, _panY)
              ..rotateX(_tiltAngle)
              ..scale(_scale)
              ..rotateZ(_rotationZ),
            child: Center(
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
                            left: (_currentPath.last.x / mapWidth) * w - 24, // Half of 48 size horizontally
                            top: (_currentPath.last.y / mapHeight) * h - 48, // Bottom anchors to destination
                            child: Transform(
                              alignment: Alignment.bottomCenter,
                              transform: Matrix4.identity()
                                ..rotateZ(-_rotationZ)
                                ..rotateX(-_tiltAngle),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.black,
                                size: 48,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWidget(String floorName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.turn_left, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$floorName ${widget.buildingModel.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _errorMessage.isNotEmpty ? _errorMessage : 'Follow the route to destination',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _errorMessage.isNotEmpty ? Colors.red : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControlsWidget() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_routeDistanceMeters}m ahead',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Flow Blue line',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'Target nearby',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Confirm Reach', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Exit Navigation', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
