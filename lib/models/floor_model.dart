class GraphNode {
  final String id;
  final String label;
  final double x;
  final double y;
  final String type; // "room" | "hallway" | "stairs" | "entrance"

  GraphNode({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.type,
  });

  factory GraphNode.fromFirestore(Map<String, dynamic> data) {
    return GraphNode(
      id: data['id'] ?? '',
      label: data['label'] ?? '',
      x: (data['x'] ?? 0.0).toDouble(),
      y: (data['y'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'hallway',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'label': label,
      'x': x,
      'y': y,
      'type': type,
    };
  }
}

class GraphEdge {
  final String from;
  final String to;
  final double weight;

  GraphEdge({
    required this.from,
    required this.to,
    required this.weight,
  });

  factory GraphEdge.fromFirestore(Map<String, dynamic> data) {
    return GraphEdge(
      from: data['from'] ?? '',
      to: data['to'] ?? '',
      weight: (data['weight'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'from': from,
      'to': to,
      'weight': weight,
    };
  }
}

class IndoorGraph {
  final String buildingId;
  final int floorNo;
  final List<double>? viewBox; // [x, y, width, height]
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  IndoorGraph({
    required this.buildingId,
    required this.floorNo,
    this.viewBox,
    required this.nodes,
    required this.edges,
  });

  factory IndoorGraph.fromFirestore(Map<String, dynamic> data) {
    // Robustly handle viewBox (could be List or Map or null)
    List<double>? viewBox;
    final vbData = data['viewBox'];
    if (vbData is List && vbData.isNotEmpty) {
      viewBox = vbData.map((e) => (e as num).toDouble()).toList();
    } else if (vbData is Map) {
      final x = (vbData['x'] ?? 0).toDouble();
      final y = (vbData['y'] ?? 0).toDouble();
      final w = (vbData['width'] ?? 0).toDouble();
      final h = (vbData['height'] ?? 0).toDouble();
      viewBox = [x, y, w, h];
    }

    // Robustly handle nodes (could be List or Map)
    final nodesData = data['nodes'];
    List<GraphNode> nodes = [];
    if (nodesData is List) {
      nodes = nodesData
          .map((n) => GraphNode.fromFirestore(n as Map<String, dynamic>))
          .toList();
    } else if (nodesData is Map) {
      nodes = nodesData.values
          .map((n) => GraphNode.fromFirestore(Map<String, dynamic>.from(n)))
          .toList();
    }

    // Robustly handle edges (could be List or Map)
    final edgesData = data['edges'];
    List<GraphEdge> edges = [];
    if (edgesData is List) {
      edges = edgesData
          .map((e) => GraphEdge.fromFirestore(e as Map<String, dynamic>))
          .toList();
    } else if (edgesData is Map) {
      edges = edgesData.values
          .map((e) => GraphEdge.fromFirestore(Map<String, dynamic>.from(e)))
          .toList();
    }

    return IndoorGraph(
      buildingId: data['buildingId'] ?? '',
      floorNo: data['floorNo'] ?? 0,
      viewBox: viewBox,
      nodes: nodes,
      edges: edges,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'buildingId': buildingId,
      'floorNo': floorNo,
      'viewBox': viewBox,
      'nodes': nodes.map((n) => n.toFirestore()).toList(),
      'edges': edges.map((e) => e.toFirestore()).toList(),
    };
  }
}

class POI {
  final String name;
  final double x;
  final double y;

  POI({
    required this.name,
    required this.x,
    required this.y,
  });

  factory POI.fromFirestore(Map<String, dynamic> data) {
    return POI(
      name: data['name'] ?? '',
      x: (data['x'] ?? 0.0).toDouble(),
      y: (data['y'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'x': x,
      'y': y,
    };
  }
}

class RoomInfo {
  final String label;
  final List<String> names;
  final String? type;

  RoomInfo({
    required this.label,
    this.names = const [],
    this.type,
  });

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      label: json['label'] ?? '',
      names: List<String>.from(json['names'] ?? []),
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        if (names.isNotEmpty) 'names': names,
        if (type != null) 'type': type,
      };
}

class FloorModel {
  final String buildingId;
  final int floorNumber;

  /// Raw SVG content stored inline (e.g. fetched from Firestore or bundled asset).
  final String? svgMapData;

  /// Remote URL (Firebase Storage or CDN) pointing to the floor plan SVG file.
  final String? svgMapUrl;

  /// Raster fallback: URL of a PNG/JPG floor map image.
  final String? mapImageUrl;

  final List<POI> pois;

  final IndoorGraph? graph;

  /// Pre-fetched room details keyed by label, bundled with offline downloads.
  final Map<String, RoomInfo> roomInfoMap;

  FloorModel({
    required this.buildingId,
    required this.floorNumber,
    this.svgMapData,
    this.svgMapUrl,
    this.mapImageUrl,
    this.pois = const [],
    this.graph,
    this.roomInfoMap = const {},
  });

  factory FloorModel.fromFirestore(
      Map<String, dynamic> data, String buildingId, int floorNumber) {
    final poisData = data['pois'];
    List<POI> pois = [];

    if (poisData is List) {
      pois = poisData
          .map((p) => POI.fromFirestore(p as Map<String, dynamic>))
          .toList();
    } else if (poisData is Map) {
      pois = poisData.values
          .map((p) => POI.fromFirestore(Map<String, dynamic>.from(p)))
          .toList();
    }

    // Parse roomInfoMap
    final roomInfoData = data['roomInfoMap'];
    Map<String, RoomInfo> roomInfoMap = {};
    if (roomInfoData is Map) {
      roomInfoMap = roomInfoData.map((key, value) => MapEntry(
            key.toString(),
            RoomInfo.fromJson(Map<String, dynamic>.from(value)),
          ));
    }

    return FloorModel(
      buildingId: buildingId,
      floorNumber: floorNumber,
      svgMapData: data['svgContent'] as String? ?? data['svgMapData'] as String?,
      svgMapUrl: data['svgMapUrl'] as String?,
      mapImageUrl: data['mapImageUrl'] as String?,
      pois: pois,
      graph: data['graph'] != null
          ? IndoorGraph.fromFirestore(data['graph'] as Map<String, dynamic>)
          : null,
      roomInfoMap: roomInfoMap,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (svgMapData != null) 'svgMapData': svgMapData,
      if (svgMapUrl != null) 'svgMapUrl': svgMapUrl,
      if (mapImageUrl != null) 'mapImageUrl': mapImageUrl,
      'pois': pois.map((p) => p.toFirestore()).toList(),
      if (graph != null) 'graph': graph!.toFirestore(),
      if (roomInfoMap.isNotEmpty)
        'roomInfoMap': roomInfoMap.map((k, v) => MapEntry(k, v.toJson())),
    };
  }
}