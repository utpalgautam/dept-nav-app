import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/building_model.dart';
import '../../models/floor_model.dart';
import '../../services/firestore_service.dart';
import '../../services/offline_storage_service.dart';

class OfflineFloorMapScreen extends StatefulWidget {
  final BuildingModel building;

  const OfflineFloorMapScreen({
    super.key,
    required this.building,
  });

  @override
  State<OfflineFloorMapScreen> createState() => _OfflineFloorMapScreenState();
}

class _OfflineFloorMapScreenState extends State<OfflineFloorMapScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final OfflineStorageService _offlineStorageService = OfflineStorageService();
  int _selectedFloor = 0; // 0 for G, 1 for 1st floor, etc.
  FloorModel? _currentFloorData;
  bool _isLoading = true;

  // View toggles
  bool _is3DMode = false;
  bool _showLabels = false;

  // Map interactive state
  double _scale = 1.0;
  double _baseScale = 1.0;
  double _panX = 0.0;
  double _panY = 0.0;
  double _rotationZ = 0.0;
  double _baseRotation = 0.0;
  final double _tiltAngle = -0.9;

  @override
  void initState() {
    super.initState();
    _loadFloorData();
  }

  Future<void> _loadFloorData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // 1. Try to load from local storage first
      FloorModel? floorData = await _offlineStorageService.getLocalFloorMap(
          widget.building.id, _selectedFloor);

      // 2. If not found locally, fetch from Firestore
      if (floorData == null) {
        floorData = await _firestoreService.getFloorMap(
            widget.building.id, _selectedFloor);
      }

      // 3. Fetch graph if missing or to ensure latest
      if (floorData != null && floorData.graph == null) {
        final graph = await _firestoreService.getIndoorGraph(
            widget.building.id, _selectedFloor);
        if (graph != null) {
          floorData = FloorModel(
            buildingId: floorData.buildingId,
            floorNumber: floorData.floorNumber,
            svgMapData: floorData.svgMapData,
            svgMapUrl: floorData.svgMapUrl,
            mapImageUrl: floorData.mapImageUrl,
            pois: floorData.pois,
            graph: graph,
          );
          // Save updated model with graph offline
          await _offlineStorageService.saveFloorMap(
              widget.building.id, _selectedFloor, floorData);
        }
      }

      setState(() {
        _currentFloorData = floorData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentFloorData = null;
      });
    }
  }

  void _onFloorSelected(int floor) {
    if (_selectedFloor != floor) {
      setState(() {
        _selectedFloor = floor;
      });
      _loadFloorData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
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
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      widget.building.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Building Details Card ---
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1D21),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Coordinates
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF333333),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Coordinates',
                                  style: TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.building.latitude.toStringAsFixed(4)}°N, ${widget.building.longitude.toStringAsFixed(4)}°E',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFF444444),
                    ),

                    const SizedBox(width: 16),

                    // Floors
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.layers_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Floors',
                              style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.building.totalFloors}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Floor Dropdown ---
              if (widget.building.totalFloors > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedFloor,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.black),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      items:
                          List.generate(widget.building.totalFloors, (index) {
                        final label =
                            index == 0 ? 'Ground Floor' : 'Floor $index';
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Row(
                            children: [
                              const Icon(Icons.layers_outlined,
                                  size: 18, color: Colors.black54),
                              const SizedBox(width: 10),
                              Text(label),
                            ],
                          ),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) _onFloorSelected(value);
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              Expanded(
                child: ClipRect(
                  clipper: const _TopOnlyClipper(),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.black))
                      : Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: _buildMapContent(),
                            ),
                            // Toggle buttons
                            Positioned(
                              top: 20,
                              right: 20,
                              child: _buildToggleButtons(),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    if (_currentFloorData == null) {
      return _buildEmptyPlaceholder();
    }

    final processedSvg = _getProcessedSvg();
    if (processedSvg.isEmpty) {
      return _buildEmptyPlaceholder();
    }

    final List<double> vb = _currentFloorData!.graph?.viewBox ?? <double>[0.0, 0.0, 800.0, 600.0];
    final double mapWidth = (vb.length > 2 && vb[2] > 0) ? vb[2] : 800.0;
    final double mapHeight = (vb.length > 3 && vb[3] > 0) ? vb[3] : 600.0;

    return LayoutBuilder(builder: (context, outerConstraints) {
      final double screenW = outerConstraints.maxWidth;
      final double screenH = outerConstraints.maxHeight;

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
        child: Container(
          color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: MatrixTransition(
                    animation: AlwaysStoppedAnimation(_rotationZ),
                    onMatrixUpdate: (animRot) {
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
                      return currentTransform;
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dot-Grid Background
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
                        // The Map
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
                                      width: w,
                                      height: h,
                                    ),
                                    if (_showLabels && !_is3DMode)
                                      ..._build2DLabelOverlays(
                                          mapWidth, mapHeight, w, h),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
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
                      ..rotateZ(_rotationZ),
                  ),
              ],
            ),
          ),
        );
      });
  }

  Widget _buildEmptyPlaceholder() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(color: const Color(0xFFFAFAFA)),
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Color(0xFFDDDDDD)),
            SizedBox(height: 16),
            Text(
              'Floor Map not available',
              style: TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
      ],
    );
  }

  String _getProcessedSvg() {
    if (_currentFloorData == null) return '';
    String svg = _currentFloorData!.svgMapData ?? '';
    if (svg.isEmpty) return '';

    final List<double> vb = _currentFloorData!.graph?.viewBox ?? <double>[0.0, 0.0, 800.0, 600.0];
    final double mapWidth = (vb.length > 2 && vb[2] > 0) ? vb[2] : 800.0;
    final double mapHeight = (vb.length > 3 && vb[3] > 0) ? vb[3] : 600.0;
    String viewBoxStr =
        '${vb.isNotEmpty ? vb[0] : 0.0} ${vb.length > 1 ? vb[1] : 0.0} $mapWidth $mapHeight';

    svg = svg.replaceFirst(RegExp(r'<svg[^>]*>'),
        '<svg viewBox="$viewBoxStr" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg">');

    return svg;
  }

  Widget _buildToggleButtons() {
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
          },
        ),
        const SizedBox(height: 12),
        _buildPremiumIconButton(
          icon: _showLabels
              ? Icons.chat_bubble_rounded
              : Icons.speaker_notes_off_rounded,
          isActive: _showLabels,
          onTap: () {
            setState(() => _showLabels = !_showLabels);
          },
        ),
      ],
    );
  }

  Widget _buildPremiumIconButton(
      {required IconData icon,
      required bool isActive,
      required VoidCallback onTap}) {
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

  List<Widget> _build2DLabelOverlays(
      double mapWidth, double mapHeight, double w, double h) {
    if (_currentFloorData?.graph == null) return [];
    final labelNodes = _currentFloorData!.graph!.nodes
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
    if (_currentFloorData?.graph == null) return [];
    final labelNodes = _currentFloorData!.graph!.nodes
        .where((n) => n.type != 'hallway' && n.label.isNotEmpty)
        .toList();

    final cx = screenW / 2.0;
    final cy = screenH / 2.0;
    final s = transform.storage;

    return labelNodes.map((node) {
      final double nx = mapLeft + (node.x / mapWidth) * displayW;
      final double ny = mapTop + (node.y / mapHeight) * displayH;
      final double px = nx - cx;
      final double py = ny - cy;
      final double xp = s[0] * px + s[4] * py + s[12];
      final double yp = s[1] * px + s[5] * py + s[13];
      final double wp = s[3] * px + s[7] * py + s[15];
      final double sx = (wp == 0 ? xp : xp / wp) + cx;
      final double sy = (wp == 0 ? yp : yp / wp) + cy;

      const double stemH = 5.0;
      const double dotR = 3.5;

      return Stack(
        clipBehavior: Clip.none,
        children: [
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
              ),
            ),
          ),
          Positioned(
            left: sx,
            top: sy - stemH - 2,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -1.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    ),
                  ),
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
}

class MatrixTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final Matrix4 Function(double) onMatrixUpdate;

  const MatrixTransition({
    super.key,
    required this.animation,
    required this.child,
    required this.onMatrixUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: onMatrixUpdate(animation.value),
          child: child,
        );
      },
      child: child,
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB).withOpacity(0.6)
      ..strokeWidth = 1.0;
    const double spacing = 15.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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

class _TopOnlyClipper extends CustomClipper<Rect> {
  const _TopOnlyClipper();

  @override
  Rect getClip(Size size) {
    // Return a rect that is effectively infinite on sides and bottom
    // but starts at y=0 (the top of the clipped area).
    return Rect.fromLTWH(-5000, 0, 10000, 10000);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
