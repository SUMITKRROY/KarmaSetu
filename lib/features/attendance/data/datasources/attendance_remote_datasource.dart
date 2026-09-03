import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';

abstract interface class AttendanceRemoteDataSource {
  Future<AttendanceModel?> getTodayAttendance({
    required String uid,
    required String date,
  });

  Stream<AttendanceModel?> streamTodayAttendance({
    required String uid,
    required String date,
  });

  Future<AttendanceModel> checkIn(AttendanceModel model);

  Future<AttendanceModel> checkOut({
    required String attendanceId,
    required DateTime checkOutTime,
    required double latitude,
    required double longitude,
    required String location,
    String? selfiePath,
    required int workingMinutes,
  });

  Future<List<AttendanceModel>> getAttendanceHistory(String uid);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final FirebaseFirestore _firestore;

  AttendanceRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'Attendance';

  @override
  Future<AttendanceModel?> getTodayAttendance({
    required String uid,
    required String date,
  }) async {
    try {
      // First try deterministic docId: ${uid}_${date}
      final docRef = _firestore.collection(_collection).doc('${uid}_$date');
      final docSnap = await docRef.get();

      if (docSnap.exists && docSnap.data() != null) {
        return AttendanceModel.fromFirestore(docSnap.data()!, docSnap.id);
      }

      // Fallback query if saved under auto-generated docId
      final querySnap = await _firestore
          .collection(_collection)
          .where('uid', isEqualTo: uid)
          .where('date', isEqualTo: date)
          .limit(1)
          .get();

      if (querySnap.docs.isNotEmpty) {
        final doc = querySnap.docs.first;
        return AttendanceModel.fromFirestore(doc.data(), doc.id);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<AttendanceModel?> streamTodayAttendance({
    required String uid,
    required String date,
  }) {
    final docId = '${uid}_$date';
    return _firestore
        .collection(_collection)
        .doc(docId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return AttendanceModel.fromFirestore(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  @override
  Future<AttendanceModel> checkIn(AttendanceModel model) async {
    final docId = model.attendanceId.isNotEmpty
        ? model.attendanceId
        : '${model.uid}_${model.date}';

    final updatedModel = model.copyWith(attendanceId: docId);

    await _firestore
        .collection(_collection)
        .doc(docId)
        .set(updatedModel.toFirestore(), SetOptions(merge: true));

    return updatedModel;
  }

  @override
  Future<AttendanceModel> checkOut({
    required String attendanceId,
    required DateTime checkOutTime,
    required double latitude,
    required double longitude,
    required String location,
    String? selfiePath,
    required int workingMinutes,
  }) async {
    final docRef = _firestore.collection(_collection).doc(attendanceId);
    final now = DateTime.now();

    final updateData = <String, dynamic>{
      'checkOut': Timestamp.fromDate(checkOutTime),
      'checkOutLatitude': latitude,
      'checkOutLongitude': longitude,
      'checkOutLocation': location,
      'workingMinutes': workingMinutes,
      'status': 'PRESENT',
      'updatedAt': Timestamp.fromDate(now),
    };

    if (selfiePath != null) {
      updateData['checkOutSelfie'] = selfiePath;
    }

    await docRef.set(updateData, SetOptions(merge: true));

    final updatedSnap = await docRef.get();
    if (updatedSnap.exists && updatedSnap.data() != null) {
      return AttendanceModel.fromFirestore(updatedSnap.data()!, updatedSnap.id);
    }

    throw Exception('Failed to retrieve updated attendance after punch out.');
  }

  @override
  Future<List<AttendanceModel>> getAttendanceHistory(String uid) async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .where('uid', isEqualTo: uid)
          .orderBy('checkIn', descending: true)
          .limit(30)
          .get();

      return snap.docs
          .map((doc) => AttendanceModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
