import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart';

class FirestoreProjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Project> createProject({
    required String name,
    required String description,
    required String createdBy, // Firebase UID
    DateTime? dueDate,
  }) async {
    final now = DateTime.now();
    final docRef = await _db.collection('projects').add({
      'name': name,
      'description': description,
      'status': 'planning',
      'createdAt': Timestamp.fromDate(now),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'createdBy': createdBy,
      'teamMembers': [createdBy],
      'progress': 0.0,
    });
    final snap = await docRef.get();
    return _fromDoc(snap);
  }

  Future<List<Project>> getProjectsForUser(String userId) async {
    final q1 = await _db
        .collection('projects')
        .where('teamMembers', arrayContains: userId)
        .get();
    final q2 = await _db
        .collection('projects')
        .where('createdBy', isEqualTo: userId)
        .get();

    final seen = <String>{};
    final all = <Project>[];
    for (final d in [...q1.docs, ...q2.docs]) {
      if (seen.add(d.id)) {
        all.add(_fromDoc(d));
      }
    }
    return all;
  }

  Future<void> deleteProject(String projectId) async {
    // Delete project document (and optionally tasks/invites via Cloud Functions or client-side cleanup)
    await _db.collection('projects').doc(projectId).delete();
  }

  Project _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data() ?? {};
    return Project(
      id: doc.id,
      name: j['name'] ?? '',
      description: j['description'] ?? '',
      status: ProjectStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (j['status'] ?? 'planning'),
        orElse: () => ProjectStatus.planning,
      ),
      createdAt: (j['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (j['dueDate'] as Timestamp?)?.toDate(),
      teamMembers: List<String>.from(j['teamMembers'] ?? const []),
      progress: (j['progress'] ?? 0.0).toDouble(),
      createdBy: j['createdBy'] ?? '',
    );
  }
}
