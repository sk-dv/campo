import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exercise.dart';
import '../models/training_session.dart';
import '../models/weight_record.dart';
import '../models/skip_record.dart';

class FirestoreService {
  static String? _uid;

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static bool get isReady => _uid != null;

  static Future<void> init() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    _uid = auth.currentUser!.uid;
  }

  static CollectionReference<Map<String, dynamic>> _userCol(String name) =>
      _db.collection('users').doc(_uid).collection(name);

  // ── Global templates ──────────────────────────────────────────────────────

  static Future<void> upsertExercise(Exercise ex) =>
      _db.collection('exercises').doc(ex.id).set(
            ex.toMap(),
            SetOptions(merge: true),
          );

  static Future<void> upsertSession(TrainingSession s) =>
      _db.collection('sessions').doc(s.id).set(
            s.toMap(),
            SetOptions(merge: true),
          );

  // ── User: completed sessions ──────────────────────────────────────────────

  static Future<void> recordCompletedSession({
    required String sessionId,
    required String weekStart,
    required List<String> exerciseIds,
  }) {
    if (!isReady) return Future.value();
    return _userCol('completed_sessions')
        .doc('${sessionId}_$weekStart')
        .set({
      'sessionId': sessionId,
      'weekStart': weekStart,
      'completedAt': FieldValue.serverTimestamp(),
      'exerciseIds': exerciseIds,
    }, SetOptions(merge: true));
  }

  // ── User: weight records ──────────────────────────────────────────────────

  static Future<void> addWeightRecord(WeightRecord w) {
    if (!isReady) return Future.value();
    return _userCol('weight_records').doc(w.id).set({
      'weightKg': w.weightKg,
      'recordedAt': Timestamp.fromDate(w.date),
    });
  }

  // ── User: skip records ────────────────────────────────────────────────────

  static Future<void> addSkipRecord(SkipRecord s) {
    if (!isReady) return Future.value();
    return _userCol('skip_records').doc(s.id).set({
      'sessionId': s.sessionId,
      'reasonIndex': s.reasonIndex,
      'date': Timestamp.fromDate(s.date),
    });
  }

  // ── User: daily check-ins (Fase 3) ────────────────────────────────────────

  static Future<void> saveDailyCheckin({
    required String date,
    required int energyLevel,
    required double sleepHours,
    required String note,
  }) {
    if (!isReady) return Future.value();
    return _userCol('daily_checkins').doc(date).set({
      'date': date,
      'energyLevel': energyLevel,
      'sleepHours': sleepHours,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── User: coach logs (Fase 4) ─────────────────────────────────────────────

  static Future<String> saveCoachLog({
    required String prompt,
    required String response,
    String? checkinDate,
  }) async {
    if (!isReady) return '';
    final ref = await _userCol('coach_logs').add({
      'prompt': prompt,
      'response': response,
      'checkinDate': checkinDate,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
