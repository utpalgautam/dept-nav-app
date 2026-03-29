import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/floor_model.dart';

class OfflineStorageService {
  static const String _downloadedMapsKey = 'downloaded_maps';

  Future<Set<String>> getDownloadedBuildingIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_downloadedMapsKey) ?? [];
    return list.toSet();
  }

  Future<void> markAsDownloaded(String buildingId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_downloadedMapsKey)?.toList() ?? [];
    if (!list.contains(buildingId)) {
      list.add(buildingId);
      await prefs.setStringList(_downloadedMapsKey, list);
    }
  }

  Future<void> removeDownloadedMap(String buildingId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_downloadedMapsKey)?.toList() ?? [];
    if (list.contains(buildingId)) {
      list.remove(buildingId);
      await prefs.setStringList(_downloadedMapsKey, list);
    }
    // Also remove local files
    await _deleteBuildingFiles(buildingId);
  }

  // --- File Storage ---

  Future<String> _getBuildingDir(String buildingId) async {
    final docDir = await getApplicationDocumentsDirectory();
    final path = '${docDir.path}/maps/$buildingId';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  Future<void> saveFloorMap(String buildingId, int floorNumber, FloorModel floorData) async {
    final dir = await _getBuildingDir(buildingId);
    final file = File('$dir/floor_$floorNumber.json');
    await file.writeAsString(jsonEncode(floorData.toFirestore()));
  }

  Future<FloorModel?> getLocalFloorMap(String buildingId, int floorNumber) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/maps/$buildingId/floor_$floorNumber.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        return FloorModel.fromFirestore(data, buildingId, floorNumber);
      }
    } catch (e) {
      print('Error loading local floor map: $e');
    }
    return null;
  }

  Future<void> _deleteBuildingFiles(String buildingId) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docDir.path}/maps/$buildingId');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      print('Error deleting building files: $e');
    }
  }
}
