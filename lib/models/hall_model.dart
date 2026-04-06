import 'dart:convert';
import 'dart:typed_data';

enum HallType { lectureHall, seminarHall, auditorium, conferenceRoom }

/// Hall model. Physical location details (building, floor, room) are
/// stored in the linked [LocationModel] document (via [locationId]).
class HallModel {
  final String id;
  final String name;
  final HallType type;
  final String? typeFromDb;

  /// ID of the corresponding document in the `locations` collection.
  final String locationId;

  final String? contactPerson;
  final String department;

  /// Legacy HTTP photo URL (may be null).
  final String? photoUrl;

  /// Base64-encoded image stored directly in Firestore as `imageUrl`.
  final String? imageUrl;

  HallModel({
    required this.id,
    required this.name,
    required this.type,
    required this.locationId,
    this.typeFromDb,
    this.contactPerson,
    this.department = 'General',
    this.photoUrl,
    this.imageUrl,
  });

  /// Decodes [imageUrl] (base64) into raw bytes for display with [Image.memory].
  Uint8List? get imageBytes {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    try {
      final raw = imageUrl!.contains(',') ? imageUrl!.split(',').last : imageUrl!;
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  factory HallModel.fromFirestore(Map<String, dynamic> data, String id) =>
      HallModel(
        id: id,
        name: data['name'] ?? '',
        type: _parseHallType(data['type']),
        typeFromDb: data['type'] as String?,
        locationId: data['locationId'] ?? '',
        contactPerson: data['contactPerson'] as String?,
        department: data['department'] ?? 'General',
        photoUrl: data['photoUrl'] as String?,
        imageUrl: data['imageUrl'] as String?,
      );

  static HallType _parseHallType(String? type) {
    switch (type?.toLowerCase()) {
      case 'seminarhall':    return HallType.seminarHall;
      case 'auditorium':     return HallType.auditorium;
      case 'conferenceroom': return HallType.conferenceRoom;
      default:               return HallType.lectureHall;
    }
  }

  String get typeString {
    String t;
    if (typeFromDb != null && typeFromDb!.isNotEmpty) {
      t = typeFromDb!.trim();
    } else {
      switch (type) {
        case HallType.lectureHall:    t = 'Lecture Hall'; break;
        case HallType.seminarHall:    t = 'Seminar Hall'; break;
        case HallType.auditorium:     t = 'Auditorium'; break;
        case HallType.conferenceRoom: t = 'Conference Room'; break;
      }
    }
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'type': type.toString().split('.').last,
        'locationId': locationId,
        if (contactPerson != null) 'contactPerson': contactPerson,
        'department': department,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}