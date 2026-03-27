import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/navigation_utils.dart';

class RouteInstruction {
  final String text;
  final double distance;
  final int time;
  final int sign;
  final List<int> interval; // Start and end indices in the polyline

  RouteInstruction({
    required this.text,
    required this.distance,
    required this.time,
    required this.sign,
    required this.interval,
  });

  factory RouteInstruction.fromJson(Map<String, dynamic> json) {
    return RouteInstruction(
      text: json['text'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      time: json['time'] ?? 0,
      sign: json['sign'] ?? 0,
      interval: List<int>.from(json['interval'] ?? [0, 0]),
    );
  }
}

class NavigationRoute {
  final List<LatLng> coordinates;
  final double distance;
  final int time;
  final List<RouteInstruction> instructions;

  NavigationRoute({
    required this.coordinates,
    required this.distance,
    required this.time,
    required this.instructions,
  });
}

class GraphHopperService {
  final String baseUrl = AppConstants.graphHopperBaseUrl;
  
  // ── Simple In-Memory Route Cache ─────────────────────────────────────
  final Map<String, _CachedRoute> _routeCache = {};

  String _generateCacheKey(LatLng start, LatLng end) {
    // Round to 5 decimal places (~1.1m precision) to catch nearby reroutes
    final sLat = start.latitude.toStringAsFixed(5);
    final sLng = start.longitude.toStringAsFixed(5);
    final dLat = end.latitude.toStringAsFixed(5);
    final dLng = end.longitude.toStringAsFixed(5);
    return "${sLat}_${sLng}_to_${dLat}_${dLng}";
  }

  /// Warms up the server by calling the /info endpoint.
  /// Retries up to 3 times if the request fails, which helps wake up Render's cold start.
  Future<bool> warmup() async {
    int retries = 3;
    while (retries > 0) {
      try {
        final url = Uri.parse('$baseUrl/info');
        final response = await http.get(url).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          debugPrint('GraphHopper Server warmed up successfully.');
          return true;
        }
      } catch (e) {
        debugPrint('Warmup attempt failed: $e. Retries left: ${retries - 1}');
      }
      retries--;
      if (retries > 0) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return false;
  }

  Future<NavigationRoute?> getRoute(LatLng start, LatLng end) async {
    final cacheKey = _generateCacheKey(start, end);
    
    // 1. Check cache (expire after 5 mins)
    if (_routeCache.containsKey(cacheKey)) {
      final cached = _routeCache[cacheKey]!;
      if (DateTime.now().difference(cached.timestamp).inMinutes < 5) {
        debugPrint('Returning cached route for $cacheKey');
        return cached.route;
      } else {
        _routeCache.remove(cacheKey);
      }
    }

    try {
      final url = Uri.parse(
          '$baseUrl/route?'
          'point=${start.latitude},${start.longitude}&'
          'point=${end.latitude},${end.longitude}&'
          'profile=foot&'
          'locale=en&'
          'points_encoded=true&'
          'instructions=true');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['paths'] != null && data['paths'].isNotEmpty) {
          final path = data['paths'][0];

          // Decode polyline points
          final String encodedPoints = path['points'];
          final List<LatLng> coordinates = NavigationUtils.decodePolyline(encodedPoints);

          // Parse instructions
          List<RouteInstruction> instructions = [];
          if (path['instructions'] != null) {
             final instList = path['instructions'] as List<dynamic>;
             instructions = instList.map((i) => RouteInstruction.fromJson(i)).toList();
          }

          final route = NavigationRoute(
            coordinates: coordinates,
            distance: (path['distance'] ?? 0.0).toDouble(),
            time: path['time'] ?? 0,
            instructions: instructions,
          );

          // 2. Add to cache
          _routeCache[cacheKey] = _CachedRoute(route: route, timestamp: DateTime.now());
          
          return route;
        } else {
            throw Exception('No path found in response');
        }
      } else {
        final body = response.body;
        print('GraphHopper API Error: ${response.statusCode} - $body');
        throw Exception('Server returned ${response.statusCode}: $body');
      }
    } catch (e) {
      print('Error fetching GraphHopper route: $e');
      rethrow;
    }
  }
  
  /// Snaps a list of GPS points to the nearest road using GraphHopper's /match API.
  Future<LatLng?> matchPoints(List<Position> points) async {
    if (points.isEmpty) return null;
    
    try {
      // 1. Construct GPX string
      final gpx = _generateGpx(points);
      
      // 2. Send POST request to /match (Using profile=foot for campus traversal)
      final url = Uri.parse('$baseUrl/match?profile=foot&type=json');
      final response = await http.post(
        url,
        body: gpx,
        headers: {'Content-Type': 'application/gpx+xml'},
      ).timeout(const Duration(seconds: 3)); // Fast timeout for responsive fallback
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['paths'] != null && data['paths'].isNotEmpty) {
          final path = data['paths'][0];
          
          // Get the last point from the matched path
          if (path['points'] != null) {
            final String encodedPoints = path['points'];
            final List<LatLng> coordinates = NavigationUtils.decodePolyline(encodedPoints);
            if (coordinates.isNotEmpty) {
              return coordinates.last;
            }
          }
        }
      } else {
        debugPrint('GraphHopper Match API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error during map matching: $e');
    }
    return null;
  }

  String _generateGpx(List<Position> points) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no" ?>');
    buffer.writeln('<gpx xmlns="http://www.topografix.com/GPX/1/1" version="1.1" creator="NITC Campus Navigator">');
    buffer.writeln('  <trk>');
    buffer.writeln('    <trkseg>');
    
    for (var p in points) {
      final timeStr = p.timestamp.toUtc().toIso8601String();
      buffer.writeln('      <trkpt lat="${p.latitude}" lon="${p.longitude}"><time>$timeStr</time></trkpt>');
    }
    
    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');
    return buffer.toString();
  }
}

class _CachedRoute {
  final NavigationRoute route;
  final DateTime timestamp;
  _CachedRoute({required this.route, required this.timestamp});
}
