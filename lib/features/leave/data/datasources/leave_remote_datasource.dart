import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leave_model.dart';

abstract interface class LeaveRemoteDataSource {
  Future<LeaveModel> applyLeave(LeaveModel model);

  Future<List<LeaveModel>> getLeavesForUser(String uid);

  Future<List<LeaveModel>> getAllLeaves();

  Stream<List<LeaveModel>> streamLeavesForUser(String uid);

  Stream<List<LeaveModel>> streamAllLeaves();

  Future<void> updateLeaveStatus({
    required String leaveId,
    required String status,
    String? remarks,
  });
}

class LeaveRemoteDataSourceImpl implements LeaveRemoteDataSource {
  final FirebaseFirestore _firestore;

  LeaveRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'Leaves';

  @override
  Future<LeaveModel> applyLeave(LeaveModel model) async {
    final docId = model.leaveId.isNotEmpty
        ? model.leaveId
        : _firestore.collection(_collection).doc().id;

    final updatedModel = model.copyWith(leaveId: docId);

    await _firestore
        .collection(_collection)
        .doc(docId)
        .set(updatedModel.toFirestore(), SetOptions(merge: true));

    return updatedModel;
  }

  @override
  Future<List<LeaveModel>> getLeavesForUser(String uid) async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs
          .map((doc) => LeaveModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<LeaveModel>> getAllLeaves() async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs
          .map((doc) => LeaveModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<List<LeaveModel>> streamLeavesForUser(String uid) {
    return _firestore
        .collection(_collection)
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => LeaveModel.fromFirestore(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Stream<List<LeaveModel>> streamAllLeaves() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => LeaveModel.fromFirestore(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> updateLeaveStatus({
    required String leaveId,
    required String status,
    String? remarks,
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
      'updatedAt': Timestamp.now(),
    };
    if (remarks != null) {
      updateData['approverRemarks'] = remarks;
    }

    await _firestore
        .collection(_collection)
        .doc(leaveId)
        .set(updateData, SetOptions(merge: true));
  }
}
