import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String userId;
  final String? userName;
  final String type;
  final String description;
  final String status; // open, in_progress, resolved
  final String priority; // low, medium, high
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, double>? location;
  final String? relatedNodeId;
  final String? adminResponse;

  ReportModel({
    required this.id,
    required this.userId,
    this.userName,
    required this.type,
    required this.description,
    this.status = 'open',
    this.priority = 'Medium',
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.relatedNodeId,
    this.adminResponse,
  });

  factory ReportModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ReportModel(
      id: id,
      userId: data['user_id'] ?? '',
      userName: data['user_name'],
      type: data['type'] ?? 'Other',
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      priority: data['priority'] ?? 'Medium',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] != null
          ? {
              'lat': (data['location']['lat'] as num).toDouble(),
              'lng': (data['location']['lng'] as num).toDouble(),
            }
          : null,
      relatedNodeId: data['related_node_id'],
      adminResponse: data['admin_response'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'user_name': userName,
      'type': type,
      'description': description,
      'status': status,
      'priority': priority,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'location': location,
      'related_node_id': relatedNodeId,
      'admin_response': adminResponse,
    };
  }

  ReportModel copyWith({
    String? status,
    DateTime? updatedAt,
    String? adminResponse,
  }) {
    return ReportModel(
      id: id,
      userId: userId,
      userName: userName,
      type: type,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location,
      relatedNodeId: relatedNodeId,
      adminResponse: adminResponse ?? this.adminResponse,
    );
  }
}
