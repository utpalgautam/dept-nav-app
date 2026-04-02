import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _reports => _firestore.collection('reports');

  // Submit a new report
  Future<void> submitReport(ReportModel report) async {
    await _reports.add(report.toFirestore());
  }

  // Get user's reports as a stream (latest first)
  Stream<List<ReportModel>> getUserReports(String userId) {
    return _reports
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs.map((doc) {
        return ReportModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      
      // Sort in memory to avoid requiring a composite index
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  // Get a single report by ID as a stream for real-time updates
  Stream<ReportModel?> streamReport(String reportId) {
    return _reports.doc(reportId).snapshots().map((doc) {
      if (doc.exists) {
        return ReportModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }
}
