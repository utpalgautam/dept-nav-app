import 'dart:convert';
import 'dart:typed_data';

/// Lab model. Physical location details (building, floor, room number) are
/// stored in the linked [LocationModel] document (via [locationId]).
class LabModel {
  final String id;
  final String name;
  final String department;

  /// ID of the corresponding document in the `locations` collection.
  final String locationId;

  final String? incharge;
  final String? inchargeEmail;
  final Map<String, String> timing;

  /// Legacy HTTP photo URL (may be null).
  final String? photoUrl;

  /// Base64-encoded image stored directly in Firestore as `imageUrl`.
  final String? imageUrl;

  LabModel({
    required this.id,
    required this.name,
    required this.department,
    required this.locationId,
    this.incharge,
    this.inchargeEmail,
    this.timing = const {},
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

  factory LabModel.fromFirestore(Map<String, dynamic> data, String id) =>
      LabModel(
        id: id,
        name: data['name'] ?? '',
        department: data['department'] ?? '',
        locationId: data['locationId'] ?? '',
        incharge: data['incharge'] as String?,
        inchargeEmail: data['inchargeEmail'] as String?,
        timing: Map<String, String>.from(data['timing'] ?? {}),
        photoUrl: data['photoUrl'] as String?,
        imageUrl: data['imageUrl'] as String?,
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'department': department,
        'locationId': locationId,
        if (incharge != null) 'incharge': incharge,
        if (inchargeEmail != null) 'inchargeEmail': inchargeEmail,
        'timing': timing,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}