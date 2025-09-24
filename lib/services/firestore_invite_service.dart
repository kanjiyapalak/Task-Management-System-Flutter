import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreInviteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create invite docs for each email
  Future<void> sendInvites({
    required String projectId,
    required List<String> emails,
    required String invitedByUid,
  }) async {
    final batch = _db.batch();
    final invitesCol = _db.collection('invites');
    final now = DateTime.now();

    for (final raw in emails) {
      final email = raw.trim().toLowerCase();
      if (email.isEmpty) continue;
      // Uniqueness: skip if there is already a pending invite for same project+email
      final existing = await invitesCol
          .where('projectId', isEqualTo: projectId)
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        continue; // skip duplicate pending invite
      }
      final docRef = invitesCol.doc();
      batch.set(docRef, {
        'projectId': projectId,
        'email': email,
        'invitedBy': invitedByUid,
        'status': 'pending',
        'createdAt': Timestamp.fromDate(now),
        'respondedAt': null,
      });
    }
    await batch.commit();
  }

  // Invites for a project
  Future<List<Map<String, dynamic>>> getProjectInvites(String projectId) async {
    final q = await _db
        .collection('invites')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .get();
    return q.docs
        .map((d) => {
              ...d.data(),
              'id': d.id,
            })
        .toList();
  }

  // Invites addressed to a specific email
  Future<List<Map<String, dynamic>>> getMyInvites(String email) async {
    final q = await _db
        .collection('invites')
        .where('email', isEqualTo: email.toLowerCase())
        .get();
    return q.docs
        .map((d) => {
              ...d.data(),
              'id': d.id,
            })
        .toList();
  }

  // Invites sent by a user (leader)
  Future<List<Map<String, dynamic>>> getSentInvitesBy(String inviterUid) async {
    final q = await _db
        .collection('invites')
        .where('invitedBy', isEqualTo: inviterUid)
        .get();
    return q.docs
        .map((d) => {
              ...d.data(),
              'id': d.id,
            })
        .toList();
  }

  // Delete an invite (only if pending)
  Future<bool> deleteInvite(String inviteId) async {
    final ref = _db.collection('invites').doc(inviteId);
    final snap = await ref.get();
    if (!snap.exists) return false;
    final data = snap.data() as Map<String, dynamic>;
    if ((data['status'] as String?) != 'pending') return false;
    await ref.delete();
    return true;
  }

  // Streams
  Stream<List<Map<String, dynamic>>> myInvitesStream(String email) {
    return _db
        .collection('invites')
        .where('email', isEqualTo: email.toLowerCase())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => {
                  ...d.data(),
                  'id': d.id,
                })
            .toList());
  }

  Stream<List<Map<String, dynamic>>> sentInvitesStream(String inviterUid) {
    return _db
        .collection('invites')
        .where('invitedBy', isEqualTo: inviterUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => {
                  ...d.data(),
                  'id': d.id,
                })
            .toList());
  }

  // Accept or decline invite; if accept, add user to project.teamMembers
  Future<bool> respondToInvite({
    required String inviteId,
    required bool accept,
    required String userId,
  }) async {
    final docRef = _db.collection('invites').doc(inviteId);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return false;
      final data = snap.data() as Map<String, dynamic>;
      final projectId = data['projectId'] as String?;
      if (projectId == null || projectId.isEmpty) return false;

      // Update invite status
      tx.update(docRef, {
        'status': accept ? 'accepted' : 'rejected',
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (accept) {
        final projectRef = _db.collection('projects').doc(projectId);
        tx.update(projectRef, {
          'teamMembers': FieldValue.arrayUnion([userId]),
        });
      }
      return true;
    });
  }
}
