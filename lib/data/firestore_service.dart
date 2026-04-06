import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campo/models/exercise.dart';
import 'package:campo/models/training_session.dart';
import 'package:campo/models/weight_record.dart';
import 'package:campo/models/skip_record.dart';

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

  // ── Config: ciclo activo ──────────────────────────────────

  /// Lee config/active_cycle de Firestore.
  /// Null si no existe o hay error.
  static Future<String?> fetchActiveCycle() async {
    try {
      final snap = await _db.collection('config').doc('active_cycle').get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return jsonEncode(data);
    } catch (_) {
      return null;
    }
  }

  // ── User: coach logs ──────────────────────────────────────────────────────

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

  /// Últimas respuestas del coach. Borra duplicados del mismo día
  /// de Firestore antes de devolver la lista.
  static Future<List<Map<String, dynamic>>> fetchCoachLogs() async {
    if (!isReady) return [];
    try {
      final snap = await _userCol('coach_logs')
          .orderBy('createdAt', descending: true)
          .get();

      // Agrupar por día — el primero (más reciente) se queda,
      // el resto se borra de Firestore.
      final seen = <String>{};
      final toDelete = <String>[];
      final result = <Map<String, dynamic>>[];

      for (final doc in snap.docs) {
        final ts = doc.data()['createdAt'];
        final date = ts is Timestamp ? ts.toDate() : DateTime.now();
        final key = '${date.year}-${date.month}-${date.day}';
        if (seen.add(key)) {
          result.add(doc.data());
        } else {
          toDelete.add(doc.id);
        }
      }

      // Borrar duplicados en paralelo
      if (toDelete.isNotEmpty) {
        await Future.wait(
          toDelete.map((id) => _userCol('coach_logs').doc(id).delete()),
        );
      }

      return result.take(10).toList();
    } catch (_) {
      return [];
    }
  }
}
