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
                                 
                                 // 1. Building Selection
                                 _buildSelectionField(
                                   label: '1. Building',
                                   hint: 'Select Building',
                                   value: _selectedBuilding?.name,
                                   icon: Icons.business_rounded,
                                   onTap: () {
                                     _showBuildingSelector();
                                   },
                                 ),
                                 const SizedBox(height: 16),

                                 // 2. Start Node Selection
                                 _buildSelectionField(
                                   label: '2. Start Point',
                                   hint: 'Select Start Point',
                                   value: _selectedStartNode != null 
                                     ? '${_selectedStartNode!.label} (${_getFloorLabel(_nodeFloorMap[_selectedStartNode])})'
                                     : null,
                                   icon: Icons.trip_origin_rounded,
                                   onTap: _selectedBuilding == null ? null : () {
                                     _showNodeSelector(isStart: true);
                                   },
                                 ),
                                 const SizedBox(height: 16),

                                 // 3. Destination Node Selection
                                 _buildSelectionField(
                                   label: '3. Destination',
                                   hint: 'Select Destination',
                                   value: _selectedEndNode != null 
                                     ? '${_selectedEndNode!.label} (${_getFloorLabel(_nodeFloorMap[_selectedEndNode])})'
                                     : null,
                                   icon: Icons.location_on_rounded,
                                   onTap: _selectedBuilding == null ? null : () {
                                     _showNodeSelector(isStart: false);
                                   },
                                 ),
                                 
                                 if (_isLoadingGraph) ...[
                                   const SizedBox(height: 16),
                                   const Center(
                                     child: SizedBox(
                                       width: 20,
                                       height: 20,
                                       child: CircularProgressIndicator(strokeWidth: 2),
                                     ),
                                   ),
                                 ],
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

  String _getFloorLabel(int? floor) {
    if (floor == null) return 'Unknown';
    return floor == 0 ? 'Ground Floor' : 'Floor $floor';
  }

  Widget _buildSelectionField({
    required String label,
    required String hint,
    required String? value,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final bool isEnabled = onTap != null;
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.grey[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEnabled ? Colors.black.withOpacity(0.1) : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isEnabled ? Colors.black87 : Colors.grey[400],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      color: value != null 
                        ? Colors.black87 
                        : (isEnabled ? Colors.black38 : Colors.grey[400]),
                      fontSize: 15,
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  Icons.unfold_more_rounded,
                  size: 20,
                  color: isEnabled ? Colors.black45 : Colors.grey[300],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showBuildingSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModernSelectorSheet<BuildingModel>(
        title: 'Select Building',
        items: _buildings,
        itemBuilder: (building) => ListTile(
          leading: const Icon(Icons.business_rounded, color: Colors.black87),
          title: Text(
            building.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${building.totalFloors} Floors Available'),
          onTap: () {
            _onBuildingChanged(building);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showNodeSelector({required bool isStart}) {
    if (_allBuildingNodes.isEmpty) return;

    // Group nodes by floor
    final Map<int, List<GraphNode>> groupedNodes = {};
    for (var node in _allBuildingNodes) {
      final floor = _nodeFloorMap[node] ?? 0;
      groupedNodes.putIfAbsent(floor, () => []).add(node);
    }
    
    final List<int> sortedFloors = groupedNodes.keys.toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NodeSelectorSheet(
        title: isStart ? 'Select Start Point' : 'Select Destination',
        groupedNodes: groupedNodes,
        sortedFloors: sortedFloors,
        onSelected: (node) {
          setState(() {
            if (isStart) {
              _selectedStartNode = node;
            } else {
              _selectedEndNode = node;
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildModernSelectorSheet<T>({
    required String title,
    required List<T> items,
    required Widget Function(T) itemBuilder,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
              itemBuilder: (context, index) => itemBuilder(items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeSelectorSheet extends StatefulWidget {
  final String title;
  final Map<int, List<GraphNode>> groupedNodes;
  final List<int> sortedFloors;
  final Function(GraphNode) onSelected;

  const _NodeSelectorSheet({
    required this.title,
    required this.groupedNodes,
    required this.sortedFloors,
    required this.onSelected,
  });

  @override
  State<_NodeSelectorSheet> createState() => _NodeSelectorSheetState();
}

class _NodeSelectorSheetState extends State<_NodeSelectorSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search room, lab, staircase...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              itemCount: widget.sortedFloors.length,
              itemBuilder: (context, floorIndex) {
                final floor = widget.sortedFloors[floorIndex];
                final nodes = widget.groupedNodes[floor]!.where((n) {
                  if (_searchQuery.isEmpty) return true;
                  return n.label.toLowerCase().contains(_searchQuery) ||
                         n.type.toLowerCase().contains(_searchQuery);
                }).toList();

                if (nodes.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        floor == 0 ? 'GROUND FLOOR' : 'FLOOR $floor',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black.withOpacity(0.4),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...nodes.map((node) => _buildNodeItem(node)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeItem(GraphNode node) {
    IconData icon;
    final iconColor = Colors.black87;
    final bgColor = const Color(0xFFF0F0F0);
    
    switch (node.type.toLowerCase()) {
      case 'room':
        icon = Icons.meeting_room_outlined;
        break;
      case 'stairs':
      case 'staircase':
        icon = Icons.stairs_rounded;
        break;
      case 'elevator':
        icon = Icons.elevator_rounded;
        break;
      case 'washroom':
        icon = Icons.wc_rounded;
        break;
      case 'entrance':
        icon = Icons.door_front_door_rounded;
        break;
      default:
        icon = Icons.place_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: () => widget.onSelected(node),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          node.label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          node.type.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black.withOpacity(0.4),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.black26),
      ),
    );
  }
}
