import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/building_model.dart';
import '../models/faculty_model.dart';
import '../models/lab_model.dart';
import '../models/hall_model.dart';
import '../models/location_model.dart';
import '../models/floor_model.dart';
import '../models/route_model.dart';
import '../models/search_log_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _buildings => _firestore.collection('buildings');
  CollectionReference get _faculties => _firestore.collection('faculty');
  CollectionReference get _labs => _firestore.collection('labs');
  CollectionReference get _halls => _firestore.collection('halls');
  CollectionReference get _locations => _firestore.collection('locations');
  CollectionReference get _floors => _firestore.collection('floormap');
  CollectionReference get _searchLogs => _firestore.collection('searchLogs');

  // ========== USER OPERATIONS ==========

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toFirestore());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  Future<void> addRecentSearch(String uid, String locationId) async {
    final docRef = _users.doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;

      List<String> recentSearches =
          List<String>.from(data['recentSearches'] ?? []);

      // Ensure it's a unique list with the newest item on top
      recentSearches.removeWhere((id) => id == locationId);
      recentSearches.insert(0, locationId);

      // Limit to 8
      if (recentSearches.length > 8) {
        recentSearches = recentSearches.sublist(0, 8);
      }

      transaction.update(docRef, {'recentSearches': recentSearches});
    });
  }

  Future<void> removeRecentSearch(String uid, String locationId) async {
    final docRef = _users.doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;

      List<String> recentSearches =
          List<String>.from(data['recentSearches'] ?? []);
      recentSearches.removeWhere((id) => id == locationId);
      transaction.update(docRef, {'recentSearches': recentSearches});
    });
  }

  Future<void> clearAllRecentSearches(String uid) async {
    await _users.doc(uid).update({'recentSearches': []});
  }

  Future<void> saveLocation(String uid, String locationId) async {
    await _users.doc(uid).update({
      'savedLocations': FieldValue.arrayUnion([locationId])
    });
  }

  Future<void> removeSavedLocation(String uid, String locationId) async {
    await _users.doc(uid).update({
      'savedLocations': FieldValue.arrayRemove([locationId])
    });
  }

  Future<void> clearAllSavedLocations(String uid) async {
    await _users.doc(uid).update({
      'savedLocations': []
    });
  }

  // ========== BUILDING OPERATIONS ==========

  Future<void> addBuilding(BuildingModel building) async {
    await _buildings.doc(building.id).set(building.toFirestore());
  }

  Future<BuildingModel?> getBuilding(String id, {Source source = Source.serverAndCache}) async {
    final doc = await _buildings.doc(id).get(GetOptions(source: source));
    if (doc.exists) {
      return BuildingModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Stream<BuildingModel> streamBuilding(String id) {
    return _buildings.doc(id).snapshots().map((doc) {
      return BuildingModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  Future<List<BuildingModel>> getAllBuildings() async {
    final snapshot = await _buildings.get();
    return snapshot.docs.map((doc) {
      return BuildingModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  Stream<List<BuildingModel>> streamAllBuildings() {
    return _buildings.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return BuildingModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // ========== FACULTY OPERATIONS ==========

  Future<void> addFaculty(FacultyModel faculty) async {
    await _faculties.doc(faculty.id).set(faculty.toFirestore());
  }

  Future<FacultyModel?> getFaculty(String id) async {
    final doc = await _faculties.doc(id).get();
    if (doc.exists) {
      return FacultyModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Stream<List<FacultyModel>> streamFacultiesByBuilding(String buildingId) {
    return _faculties
        .where('buildingId', isEqualTo: buildingId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FacultyModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Stream<List<FacultyModel>> streamAllFaculties() {
    return _faculties.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FacultyModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // ========== LAB OPERATIONS ==========

  Future<void> addLab(LabModel lab) async {
    await _labs.doc(lab.id).set(lab.toFirestore());
  }

  Future<LabModel?> getLab(String id) async {
    final doc = await _labs.doc(id).get();
    if (doc.exists) {
      return LabModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Stream<List<LabModel>> streamLabsByBuilding(String buildingId) {
    return _labs
        .where('buildingId', isEqualTo: buildingId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return LabModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Stream<List<LabModel>> streamAllLabs() {
    return _labs.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return LabModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // ========== HALL OPERATIONS ==========

  Future<void> addHall(HallModel hall) async {
    await _halls.doc(hall.id).set(hall.toFirestore());
  }

  Future<HallModel?> getHall(String id) async {
    final doc = await _halls.doc(id).get();
    if (doc.exists) {
      return HallModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Stream<List<HallModel>> streamHallsByBuilding(String buildingId) {
    return _halls
        .where('buildingId', isEqualTo: buildingId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HallModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Stream<List<HallModel>> streamAllHalls() {
    return _halls.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return HallModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<FacultyModel?> getFacultyByLocationId(String locationId) async {
    final query = await _faculties.where('locationId', isEqualTo: locationId).limit(1).get();
    if (query.docs.isNotEmpty) {
      return FacultyModel.fromFirestore(query.docs.first.data() as Map<String, dynamic>, query.docs.first.id);
    }
    return null;
  }

  Future<HallModel?> getHallByLocationId(String locationId) async {
    final query = await _halls.where('locationId', isEqualTo: locationId).limit(1).get();
    if (query.docs.isNotEmpty) {
      return HallModel.fromFirestore(query.docs.first.data() as Map<String, dynamic>, query.docs.first.id);
    }
    return null;
  }

  Future<LabModel?> getLabByLocationId(String locationId) async {
    final query = await _labs.where('locationId', isEqualTo: locationId).limit(1).get();
    if (query.docs.isNotEmpty) {
      return LabModel.fromFirestore(query.docs.first.data() as Map<String, dynamic>, query.docs.first.id);
    }
    return null;
  }

  // ========== SEARCH OPERATIONS ==========

  Future<LocationModel?> getLocation(String id) async {
    final doc = await _locations.doc(id).get();
    if (doc.exists) {
      return LocationModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  bool _isSubsequence(String query, String target) {
    if (query.isEmpty) return true;
    int qIdx = 0;
    for (int i = 0; i < target.length; i++) {
      if (query[qIdx] == target[i]) {
        qIdx++;
        if (qIdx == query.length) return true;
      }
    }
    return false;
  }

  Future<List<LocationModel>> searchLocations(String query) async {
    // Format the query by removing internal spaces so it accurately slides through the subsequence check
    final searchQuery = query.toLowerCase().replaceAll(' ', '');

    final snapshot = await _locations.where('isActive', isEqualTo: true).get();

    // Filter in memory (Firestore doesn't support text search natively)
    final allMatches = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final tags = List<String>.from(data['tags'] ?? []);
      final roomNumber = (data['roomNumber'] ?? '').toString().toLowerCase();

      bool matchesName = _isSubsequence(searchQuery, name);
      bool matchesTags = tags.any((tag) => _isSubsequence(searchQuery, tag.toLowerCase()));
      bool matchesRoom = _isSubsequence(searchQuery, roomNumber);

      return matchesName || matchesTags || matchesRoom;
    }).map((doc) {
      return LocationModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    // Deduplicate results directly resolving overlapping string permutations
    final Set<String> seenNames = {};
    final List<LocationModel> uniqueResults = [];

    for (var loc in allMatches) {
      // Strip out punctuation and spaces for identity comparison (e.g. 'Jayaraj P B' == 'Jayaraj P. B.')
      String normName = loc.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (!seenNames.contains(normName)) {
        seenNames.add(normName);
        uniqueResults.add(loc);
      }
    }

    return uniqueResults;
  }

  Future<void> incrementSearchCount(String locationId) async {
    await _locations
        .doc(locationId)
        .update({'searchCount': FieldValue.increment(1)});
  }

  Future<List<LocationModel>> getPopularLocations({int limit = 10}) async {
    try {
      // Fetching slightly more to account for client-side filtering of inactive locations,
      // avoiding the need for a composite index on Firestore.
      final snapshot = await _locations
          .orderBy('searchCount', descending: true)
          .limit(limit + 10)
          .get();

      return snapshot.docs
          .map((doc) {
            return LocationModel.fromFirestore(
                doc.data() as Map<String, dynamic>, doc.id);
          })
          .where((loc) => loc.isActive)
          .take(limit)
          .toList();
    } catch (e) {
      // Fallback in case of any permissions or index issues
      print('Error fetching popular locations: $e');
      return [];
    }
  }

  Future<List<LocationModel>> getLocationsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Firestore 'whereIn' limits to 10 items.
    final limitedIds = ids.take(10).toList();

    final snapshot = await _locations
        .where(FieldPath.documentId, whereIn: limitedIds)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      return LocationModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // ========== FLOOR MAP OPERATIONS ==========

  Future<String?> uploadFloorMap({
    required String buildingId,
    required int floor,
    required String filePath,
  }) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);
    final dataUri = 'data:image/jpeg;base64,$base64Image';
    return dataUri;
  }

  Future<void> saveFloorMapData(
      String buildingId, int floor, FloorModel floorData) async {
    // Generate an ID for the floor document, e.g., 'buildingId_floor_floorNumber'
    final docId = '${buildingId}_floor_$floor';
    await _floors.doc(docId).set(floorData.toFirestore());
  }

  Future<FloorModel?> getFloorMap(String buildingId, int floor, {Source source = Source.serverAndCache}) async {
    final querySnapshot = await _floors
        .where('buildingId', isEqualTo: buildingId)
        .where('floorNumber', isEqualTo: floor)
        .limit(1)
        .get(GetOptions(source: source));

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      return FloorModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        buildingId,
        floor,
      );
    }
    return null;
  }

  // ========== INDOOR GRAPH OPERATIONS ==========

  /// Fetches an [IndoorGraph] from the `IndoorGraphs` collection.
  /// Document ID format: `{buildingId}_floor_{floorNo}` (e.g. `B3_floor_0`).
  Future<IndoorGraph?> getIndoorGraph(String buildingId, int floorNo) async {
    final docId = '${buildingId}_floor_$floorNo';
    final doc = await _firestore.collection('IndoorGraphs').doc(docId).get();
    if (doc.exists && doc.data() != null) {
      return IndoorGraph.fromFirestore(doc.data()!);
    }
    return null;
  }

  // ========== ROUTE OPERATIONS ==========

  Future<RouteModel?> getRoute(String buildingId, int floorNumber,
      String fromLocation, String toLocation) async {
    final querySnapshot = await _firestore
        .collection('routes')
        .where('buildingId', isEqualTo: buildingId)
        .where('floorNumber', isEqualTo: floorNumber)
        .where('fromLocation', isEqualTo: fromLocation)
        .where('toLocation', isEqualTo: toLocation)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      return RouteModel.fromFirestore(doc.data(), doc.id);
    }

    return null;
  }

  // ========== ANALYTICS / LOGGING ==========

  Future<void> logSearch(SearchLogModel log) async {
    await _searchLogs.add(log.toFirestore());
  }

  // ========== ROOM INFO FOR OFFLINE MAP LABELS ==========

  /// Fetches room details for a list of labels in a given building.
  /// Matches labels against the `locations` collection, robustly grouping
  /// by room number/name to support multiple entities (e.g. multiple 
  /// faculties in one cabin).
  Future<Map<String, RoomInfo>> fetchRoomInfoForLabels(
      String buildingId, int floorNumber, List<String> labels) async {
    if (labels.isEmpty) return {};

    final Map<String, RoomInfo> result = {};

    try {
      // Fetch all locations to handle missing/wrong building IDs or inactive fields
      final snapshot = await _locations.get();
      final allLocations = <LocationModel>[];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Simple in-memory filter to be robust to missingisActive fields
          if (data['isActive'] == false) continue;
          
          allLocations.add(LocationModel.fromFirestore(data, doc.id));
        } catch (e) {
          // If one record is corrupted, we skip it instead of failing the whole floor
          print('Error parsing location ${doc.id}: $e');
        }
      }

      for (final label in labels) {
        final targetLabel = label.trim().toLowerCase();
        if (targetLabel.isEmpty) continue;

        final List<LocationModel> matches = [];

        for (final loc in allLocations) {
          final locRoom = (loc.roomNumber ?? '').trim().toLowerCase();

          // Strict match: Compare labels with roomNumber field directly
          if (locRoom.isNotEmpty && locRoom == targetLabel) {
            matches.add(loc);
          }
        }

        if (matches.isEmpty) {
          result[label] = RoomInfo(label: label);
        } else {
          // Deduplicate names and pick a type
          final namesSet = matches.map((m) => m.name.trim()).toSet();
          final List<String> names = namesSet.toList();
          
          // Sort names to be consistent
          names.sort();

          // Determine predominant type
          String? typeStr;
          if (matches.any((m) => m.type == LocationType.faculty)) {
            typeStr = 'Faculty Cabin';
          } else if (matches.any((m) => m.type == LocationType.lab)) {
            typeStr = 'Laboratory';
          } else if (matches.any((m) => m.type == LocationType.hall)) {
            typeStr = 'Hall';
          } else {
            typeStr = matches.first.typeString;
          }
          
          result[label] = RoomInfo(
            label: label,
            names: names,
            type: typeStr,
          );
        }
      }
    } catch (e) {
      // On failure, return what we have or empty
    }

    return result;
  }
}
