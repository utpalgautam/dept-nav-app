import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../directory/directory_screen.dart';
import '../map/offline_maps_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/firestore_service.dart';
import '../../models/building_model.dart';
import '../../models/floor_model.dart';

// Import for the future view screen
import 'indoor_route_view_screen.dart';
import 'indoor_navigation_screen.dart';

class IndoorNavigationSetupScreen extends StatefulWidget {
  const IndoorNavigationSetupScreen({super.key});

  @override
  State<IndoorNavigationSetupScreen> createState() =>
      _IndoorNavigationSetupScreenState();
}

class _IndoorNavigationSetupScreenState
    extends State<IndoorNavigationSetupScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoadingBuildings = true;
  List<BuildingModel> _buildings = [];
  BuildingModel? _selectedBuilding;

  List<int> _availableFloors = [];
  int? _selectedFloor;

  bool _isLoadingGraph = false;
  IndoorGraph? _currentGraph;

  List<GraphNode> _allBuildingNodes = [];
  Map<GraphNode, int> _nodeFloorMap = {};

  GraphNode? _selectedStartNode;
  GraphNode? _selectedEndNode;

  @override
  void initState() {
    super.initState();
    debugPrint('IndoorNavigationSetupScreen: initState');
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    debugPrint('IndoorNavigationSetupScreen: _loadBuildings started');
    try {
      final buildings = await _firestoreService.getAllBuildings();
      debugPrint(
          'IndoorNavigationSetupScreen: _loadBuildings loaded ${buildings.length} buildings');
      if (mounted) {
        setState(() {
          _buildings = buildings;
          _isLoadingBuildings = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading buildings: $e');
      if (mounted) {
        setState(() {
          _isLoadingBuildings = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load buildings.')),
        );
      }
    }
  }

  void _onBuildingChanged(BuildingModel? building) {
    if (building == null) return;
    setState(() {
      _selectedBuilding = building;
      _selectedFloor = null;
      _currentGraph = null;
      _selectedStartNode = null;
      _selectedEndNode = null;
      _allBuildingNodes = [];
      _nodeFloorMap = {};
      _isLoadingGraph = true;
    });
    _loadAllBuildingNodes(building);
  }

  Future<void> _loadAllBuildingNodes(BuildingModel building) async {
    try {
      List<GraphNode> aggregatedNodes = [];
      Map<GraphNode, int> floorMap = {};

      // Fetch all floor graphs in parallel
      final futures = List.generate(building.totalFloors,
          (floor) => _firestoreService.getIndoorGraph(building.id, floor));
      final graphs = await Future.wait(futures);

      for (var graph in graphs) {
        if (graph != null) {
          final validNodes = graph.nodes
              .where((n) => n.type.toLowerCase() != 'hallway')
              .toList();
          aggregatedNodes.addAll(validNodes);
          for (var node in validNodes) {
            floorMap[node] = graph.floorNo;
          }
        }
      }

      if (mounted) {
        setState(() {
          _allBuildingNodes = aggregatedNodes;
          _nodeFloorMap = floorMap;
          _isLoadingGraph = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading building nodes: $e');
      if (mounted) {
        setState(() => _isLoadingGraph = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to load building destinations.')),
        );
      }
    }
  }

  Future<void> _onStartNavigation() async {
    if (_selectedBuilding == null ||
        _selectedStartNode == null ||
        _selectedEndNode == null) {
      return;
    }

    final startFloor = _nodeFloorMap[_selectedStartNode] ?? 0;
    final endFloor = _nodeFloorMap[_selectedEndNode] ?? 0;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IndoorNavigationScreen(
          buildingId: _selectedBuilding!.id,
          buildingName: _selectedBuilding!.name,
          floor: startFloor,
          entryPointId: _selectedStartNode!.id,
          destinationLocationId: null,
          destinationNodeId: _selectedEndNode!.id,
          destinationNodeLabel: _selectedEndNode!.label,
          targetFloor: endFloor,
        ),
      ),
    );

    if (mounted) {
      setState(() => _sliderPosition = 0.0);
    }
  }

  void _onNavItemTapped(int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (index == 1) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DirectoryScreen()));
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
    debugPrint(
        'IndoorNavigationSetupScreen: build (isLoading: $_isLoadingBuildings, buildings: ${_buildings.length})');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: _isLoadingBuildings
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 120.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Custom Header matching Offline Maps
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white),
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
                              const Text(
                                'Navigate Inside Building',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Content Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 10)
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Select Route',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                const SizedBox(height: 24),
                                _buildDropdown<BuildingModel>(
                                  label: '1. Building',
                                  hint: 'Select Building',
                                  value: _selectedBuilding,
                                  items: _buildings.map((b) {
                                    return DropdownMenuItem(
                                      value: b,
                                      child: Text(b.name),
                                    );
                                  }).toList(),
                                  onChanged: _onBuildingChanged,
                                ),
                                const SizedBox(height: 16),
                                const SizedBox(height: 16),
                                _buildDropdown<GraphNode>(
                                  label: '2. Start Node',
                                  hint: 'Select Start Node',
                                  value: _selectedStartNode,
                                  items: _allBuildingNodes.map((n) {
                                    final floor = _nodeFloorMap[n];
                                    final floorLabel =
                                        floor == 0 ? 'GF' : 'F$floor';
                                    return DropdownMenuItem(
                                      value: n,
                                      child: Text(
                                          '${n.label} (${n.type}, $floorLabel)'),
                                    );
                                  }).toList(),
                                  onChanged: _allBuildingNodes.isEmpty
                                      ? null
                                      : (val) => setState(
                                          () => _selectedStartNode = val),
                                ),
                                const SizedBox(height: 16),
                                _buildDropdown<GraphNode>(
                                  label: '3. Destination Node',
                                  hint: 'Select Destination Node',
                                  value: _selectedEndNode,
                                  items: _allBuildingNodes.map((n) {
                                    final floor = _nodeFloorMap[n];
                                    final floorLabel =
                                        floor == 0 ? 'GF' : 'F$floor';
                                    return DropdownMenuItem(
                                      value: n,
                                      child: Text(
                                          '${n.label} (${n.type}, $floorLabel)'),
                                    );
                                  }).toList(),
                                  onChanged: _allBuildingNodes.isEmpty
                                      ? null
                                      : (val) => setState(
                                          () => _selectedEndNode = val),
                                ),
                                const SizedBox(height: 48),
                                _buildStartNavigationSlider(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: CustomBottomNavBar(
              currentIndex: 2,
              onTap: _onNavItemTapped,
            ),
          ),
        ],
      ),
    );
  }

  double _sliderPosition = 0.0;

  Widget _buildStartNavigationSlider() {
    bool isEnabled = _selectedBuilding != null &&
        _selectedStartNode != null &&
        _selectedEndNode != null;

    return Container(
      height: 64,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isEnabled ? Colors.black.withOpacity(0.05) : Colors.grey[200],
        borderRadius: BorderRadius.circular(32),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth =
              constraints.maxWidth - 64; // Account for handle width
          return Stack(
            children: [
              Center(
                child: Opacity(
                  opacity: (1.0 - (_sliderPosition / maxWidth)).clamp(0.0, 1.0),
                  child: Text(
                    'Slide to Start Navigation',
                    style: TextStyle(
                      color: isEnabled ? Colors.black54 : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: _sliderPosition,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: isEnabled
                      ? (details) {
                          setState(() {
                            _sliderPosition += details.delta.dx;
                            _sliderPosition =
                                _sliderPosition.clamp(0.0, maxWidth);
                          });
                        }
                      : null,
                  onHorizontalDragEnd: isEnabled
                      ? (details) {
                          if (_sliderPosition > maxWidth * 0.8) {
                            setState(() => _sliderPosition = maxWidth);
                            _onStartNavigation();
                          } else {
                            setState(() => _sliderPosition = 0.0);
                          }
                        }
                      : null,
                  child: _buildSliderHandle(isEnabled),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliderHandle(bool isEnabled) {
    return Container(
      width: 56,
      height: 56,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.black : Colors.grey[400],
        shape: BoxShape.circle,
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: hint,
          container: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                hint: Text(hint),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
