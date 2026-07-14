import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/email_api.dart';

class ConnectionRepository {
  ConnectionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    EmailApiClient? emailApi,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _emailApi = emailApi ?? EmailApiClient();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EmailApiClient _emailApi;

  CollectionReference<Map<String, dynamic>> _usersCollection() =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _connections(String userId) =>
      _usersCollection()
          .doc(userId)
          .collection('connections');

  Future<void> sendConnectionRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    final batch = _firestore.batch();
    final fromDoc = _connections(fromUserId).doc(toUserId);
    final toDoc = _connections(toUserId).doc(fromUserId);

    batch.set(fromDoc, {
      'status': 'pending',
      'direction': 'outgoing',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(toDoc, {
      'status': 'pending',
      'direction': 'incoming',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Fire-and-forget notification. The connection request is already saved; a
    // down/slow/unconfigured email server must not block or fail it, so the
    // email is never awaited here.
    unawaited(_notifyConnection(toUserId));
  }

  Future<void> _notifyConnection(String toUserId) async {
    try {
      final token = await _auth.currentUser?.getIdToken();
      if (token != null) {
        await _emailApi.sendConnectionRequest(idToken: token, toUserId: toUserId);
      }
    } catch (_) {
      // Best-effort only; ignore any email failure.
    }
  }

  Future<void> acceptConnection({
    required String userId,
    required String otherUserId,
  }) async {
    final batch = _firestore.batch();
    final userDoc = _connections(userId).doc(otherUserId);
    final otherDoc = _connections(otherUserId).doc(userId);

    batch.update(userDoc, {
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(otherDoc, {
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> declineConnection({
    required String userId,
    required String otherUserId,
  }) async {
    final batch = _firestore.batch();
    batch.delete(_connections(userId).doc(otherUserId));
    batch.delete(_connections(otherUserId).doc(userId));
    await batch.commit();
  }

  Stream<List<ConnectionRecord>> watchConnections(String userId) {
    return _connections(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final records = <ConnectionRecord>[];
      for (final doc in snapshot.docs) {
        final otherUserId = doc.id;
        final status = doc['status'] as String? ?? 'pending';
        final direction = doc['direction'] as String? ?? 'outgoing';
        final userSnapshot = await _usersCollection().doc(otherUserId).get();
        final data = userSnapshot.data() ?? <String, dynamic>{};
        records.add(
          ConnectionRecord(
            userId: otherUserId,
            email: (data['email'] as String? ?? '').toString(),
            displayName: (data['displayName'] as String? ?? '').toString(),
            status: status,
            direction: direction,
          ),
        );
      }
      return records;
    });
  }

  Future<String?> findUserIdByEmail(String email) async {
    final query = await _usersCollection()
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      return null;
    }
    return query.docs.first.id;
  }
}

class ConnectionRecord {
  const ConnectionRecord({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.status,
    required this.direction,
  });

  final String userId;
  final String email;
  final String displayName;
  final String status; // pending, accepted
  final String direction; // incoming, outgoing

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isIncoming => direction == 'incoming';
  bool get isOutgoing => direction == 'outgoing';
}
