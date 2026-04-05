import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise.dart';
import '../models/training_session.dart';
import '../models/check_record.dart';
import '../models/weight_record.dart';
import '../models/skip_record.dart';
import '../models/day_record.dart';
import 'seed_data.dart';
import 'firestore_service.dart';

class HiveService {
  static const String exercisesBox = 'exercises';
  static const String sessionsBox = 'sessions';
  static const String checkRecordsBox = 'check_records';
  static const String metaBox = 'meta';
  static const String weightRecordsBox = 'weight_records';
  static const String skipRecordsBox = 'skip_records';
  static const String dayRecordsBox = 'day_records';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ExerciseCategoryAdapter());
    Hive.registerAdapter(ExerciseAdapter());
    Hive.registerAdapter(TrainingSessionAdapter());
    Hive.registerAdapter(CheckRecordAdapter());
    Hive.registerAdapter(WeightRecordAdapter());
    Hive.registerAdapter(SkipRecordAdapter());
    Hive.registerAdapter(DayRecordAdapter());

    await Hive.openBox<Exercise>(exercisesBox);
    await Hive.openBox<TrainingSession>(sessionsBox);
    await Hive.openBox<CheckRecord>(checkRecordsBox);
    await Hive.openBox(metaBox);
    await Hive.openBox<WeightRecord>(weightRecordsBox);
    await Hive.openBox<SkipRecord>(skipRecordsBox);
    await Hive.openBox<DayRecord>(dayRecordsBox);

    await _seedIfNeeded();
  }

  static Future<void> _seedIfNeeded() async {
    final meta = Hive.box(metaBox);
    if (meta.get('seeded_v3') == true) return;

    // Exercises + sessions
    final exerciseBox = Hive.box<Exercise>(exercisesBox);
    final sessionBox = Hive.box<TrainingSession>(sessionsBox);
    for (final ex in SeedData.buildExercises()) {
      await exerciseBox.put(ex.id, ex);
    }
    for (final s in SeedData.buildSessions()) {
      await sessionBox.put(s.id, s);
    }

    // Active cycle: Hacia el partido del 12 de abril
    await meta.put('active_cycle', jsonEncode({
      'name': 'Hacia el partido del 12 de abril',
      'startDate': '2026-04-01',
      'endDate': '2026-04-12',
      'weeks': [
        {
          'weekStart': '2026-03-30',
          'target': 3,
          'sessionIds': ['sesion-001', 'sesion-correr-1', 'sesion-fuerza-1'],
        },
        {
          'weekStart': '2026-04-06',
          'target': 5,
          'sessionIds': [
            'sesion-001',
            'sesion-correr-2',
            'sesion-fuerza-1',
            'sesion-tecnica-2',
            'sesion-potencia-tiro',
          ],
        },
        {
          'weekStart': '2026-04-11',
          'target': 1,
          'sessionIds': ['sesion-pre-partido'],
        },
      ],
    }));

    // Peso inicial: 67 kg, 31 marzo 2026
    final weightBox = Hive.box<WeightRecord>(weightRecordsBox);
    await weightBox.put('weight-2026-03-31', WeightRecord(
      id: 'weight-2026-03-31',
      date: DateTime(2026, 3, 31),
      weightKg: 67.0,
    ));

    // Días de contexto pre-ciclo (sesión 1 con entrenador)
    final dayBox = Hive.box<DayRecord>(dayRecordsBox);
    await dayBox.put('day-2026-03-29', DayRecord(
      id: 'day-2026-03-29',
      date: DateTime(2026, 3, 29),
      activityType: 'partido',
      completed: true,
      partialCompletion: true,
      notes: 'Llegó tarde, jugó ~50% del partido.',
    ));
    await dayBox.put('day-2026-03-30', DayRecord(
      id: 'day-2026-03-30',
      date: DateTime(2026, 3, 30),
      activityType: 'correr',
      completed: true,
      notes: 'Salió a correr, le encantó. Buena señal de motivación.',
    ));
    await dayBox.put('day-2026-03-31', DayRecord(
      id: 'day-2026-03-31',
      date: DateTime(2026, 3, 31),
      activityType: 'futbol_tecnico',
      completed: false,
      notes: 'Tiempo de calidad con su pareja. Nutrición personal, no fallo de disciplina.',
    ));

    // SkipRecord para el martes 31 (sesión 001 skipped con motivo)
    final skipBox = Hive.box<SkipRecord>(skipRecordsBox);
    await skipBox.put('skip-sesion-001-2026-03-31', SkipRecord(
      id: 'skip-sesion-001-2026-03-31',
      date: DateTime(2026, 3, 31),
      sessionId: 'sesion-001',
      reasonIndex: 1, // nutricion_personal
    ));

    await meta.put('seeded_v3', true);
    // Borrar flag viejo si existe
    await meta.delete('seeded');
  }

  // ── Boxes ─────────────────────────────────────────────────────────────────

  static Box<Exercise> get exercises => Hive.box<Exercise>(exercisesBox);
  static Box<TrainingSession> get sessions =>
      Hive.box<TrainingSession>(sessionsBox);
  static Box<CheckRecord> get checkRecords =>
      Hive.box<CheckRecord>(checkRecordsBox);
  static Box<WeightRecord> get weightRecords =>
      Hive.box<WeightRecord>(weightRecordsBox);
  static Box<SkipRecord> get skipRecords =>
      Hive.box<SkipRecord>(skipRecordsBox);
  static Box<DayRecord> get dayRecords =>
      Hive.box<DayRecord>(dayRecordsBox);

  // ── Check record helpers ──────────────────────────────────────────────────

  static String checkKey(String exerciseId, String sessionId, DateTime date) {
    final d = '${date.year}-${date.month}-${date.day}';
    return '$exerciseId|$sessionId|$d';
  }

  static CheckRecord? getCheck(
      String exerciseId, String sessionId, DateTime date) {
    return checkRecords.get(checkKey(exerciseId, sessionId, date));
  }

  static Future<void> toggleCheck(
      String exerciseId, String sessionId, DateTime date) async {
    final key = checkKey(exerciseId, sessionId, date);
    final existing = checkRecords.get(key);
    if (existing == null) {
      await checkRecords.put(
        key,
        CheckRecord(
          id: key,
          exerciseId: exerciseId,
          sessionId: sessionId,
          completedDate: date,
          isDone: true,
        ),
      );
    } else {
      existing.isDone = !existing.isDone;
      await existing.save();
    }
    _syncCompletedSessionIfNeeded(sessionId);
  }

  static void _syncCompletedSessionIfNeeded(String sessionId) {
    if (!isSessionDoneThisWeek(sessionId)) return;
    final session = sessions.get(sessionId);
    if (session == null) return;
    final ws = _thisWeekStart();
    final weekStartStr =
        '${ws.year}-${ws.month.toString().padLeft(2, '0')}-${ws.day.toString().padLeft(2, '0')}';
    unawaited(FirestoreService.recordCompletedSession(
      sessionId: sessionId,
      weekStart: weekStartStr,
      exerciseIds: session.exerciseIds,
    ));
  }

  static bool isChecked(String exerciseId, String sessionId, DateTime date) {
    return getCheck(exerciseId, sessionId, date)?.isDone ?? false;
  }

  /// Toggle check usando la fecha de HOY (para el pool semanal).
  static Future<void> toggleCheckToday(
      String exerciseId, String sessionId) async {
    final today = DateTime.now();
    await toggleCheck(
        exerciseId, sessionId, DateTime(today.year, today.month, today.day));
  }

  static bool isCheckedToday(String exerciseId, String sessionId) {
    final today = DateTime.now();
    return isChecked(
        exerciseId, sessionId, DateTime(today.year, today.month, today.day));
  }

  // ── Pool / semana helpers ─────────────────────────────────────────────────

  static DateTime _thisWeekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Sesión completada en CUALQUIER momento de esta semana.
  static bool isSessionDoneThisWeek(String sessionId) {
    final session = sessions.get(sessionId);
    if (session == null) return false;
    if (session.exerciseIds.isEmpty) return false;
    final weekStart = _thisWeekStart();
    final weekEnd = weekStart.add(const Duration(days: 7));
    return session.exerciseIds.every((exId) {
      return checkRecords.values.any((r) =>
          r.exerciseId == exId &&
          r.sessionId == sessionId &&
          r.isDone &&
          !r.completedDate.isBefore(weekStart) &&
          r.completedDate.isBefore(weekEnd));
    });
  }

  /// Hubo actividad (algún ejercicio chequeado) en una fecha específica.
  static bool hasActivityOnDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return checkRecords.values.any((r) =>
        r.isDone &&
        !r.completedDate.isBefore(dayStart) &&
        r.completedDate.isBefore(dayEnd));
  }

  static bool isSkippedThisWeek(String sessionId) {
    final weekStart = _thisWeekStart();
    final weekEnd = weekStart.add(const Duration(days: 7));
    return skipRecords.values.any((r) =>
        r.sessionId == sessionId &&
        !r.date.isBefore(weekStart) &&
        r.date.isBefore(weekEnd));
  }

  /// IDs de sesiones del pool para esta semana según el ciclo activo.
  static List<String> currentWeekSessionIds() {
    final cycle = activeCycle;
    if (cycle == null) {
      return sessions.keys.cast<String>().toList();
    }
    final weeks = cycle['weeks'] as List<dynamic>;
    final weekStart = _thisWeekStart();
    for (final week in weeks) {
      final ws = DateTime.parse(week['weekStart'] as String);
      if (ws.year == weekStart.year &&
          ws.month == weekStart.month &&
          ws.day == weekStart.day) {
        return (week['sessionIds'] as List<dynamic>).cast<String>();
      }
    }
    return sessions.keys.cast<String>().toList();
  }

  static int currentWeekTarget() {
    final cycle = activeCycle;
    if (cycle == null) return 3;
    final weeks = cycle['weeks'] as List<dynamic>;
    final weekStart = _thisWeekStart();
    for (final week in weeks) {
      final ws = DateTime.parse(week['weekStart'] as String);
      if (ws.year == weekStart.year &&
          ws.month == weekStart.month &&
          ws.day == weekStart.day) {
        return (week['target'] as int?) ?? 3;
      }
    }
    return 3;
  }

  static int sessionsCompletedThisWeek() {
    final ids = currentWeekSessionIds();
    return ids.where((id) => isSessionDoneThisWeek(id)).length;
  }

  // ── Active cycle ──────────────────────────────────────────────────────────

  static Map<String, dynamic>? get activeCycle {
    final raw = Hive.box(metaBox).get('active_cycle');
    if (raw == null) return null;
    try {
      return jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static DateTime? get cycleEndDate {
    final end = activeCycle?['endDate'] as String?;
    return end != null ? DateTime.parse(end) : null;
  }

  static String? get cycleName => activeCycle?['name'] as String?;

  static int daysUntilCycleEnd() {
    final endDate = cycleEndDate;
    if (endDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return endDate.difference(today).inDays;
  }

  // ── Day type override ─────────────────────────────────────────────────────

  static String getDayType(DateTime date) {
    final key = 'day_type_${_isoDate(date)}';
    return Hive.box(metaBox).get(key) as String? ?? _defaultDayType(date.weekday);
  }

  static Future<void> setDayType(DateTime date, String type) async {
    final key = 'day_type_${_isoDate(date)}';
    await Hive.box(metaBox).put(key, type);
  }

  static String _defaultDayType(int weekday) {
    if (weekday == DateTime.saturday) return 'descanso';
    if (weekday == DateTime.sunday) return 'partido';
    return 'entrenamiento';
  }

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Legacy helpers (ejercicio detail + checks históricos) ─────────────────

  static bool isSessionComplete(String sessionId, DateTime date) {
    final session = sessions.get(sessionId);
    if (session == null) return false;
    return session.exerciseIds
        .every((exId) => isChecked(exId, sessionId, date));
  }

  static int weekCompletedCount(DateTime weekStart) {
    return sessionsCompletedThisWeek();
  }

  static int completedThisWeekForExercise(String exerciseId) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    int count = 0;
    for (final record in checkRecords.values) {
      if (record.exerciseId == exerciseId && record.isDone) {
        final d = record.completedDate;
        final weekStart =
            DateTime(monday.year, monday.month, monday.day);
        if (!d.isBefore(weekStart) &&
            d.isBefore(weekStart.add(const Duration(days: 7)))) {
          count++;
        }
      }
    }
    return count;
  }

  // ── Weight helpers ────────────────────────────────────────────────────────

  static WeightRecord? get latestWeight {
    if (weightRecords.isEmpty) return null;
    return weightRecords.values
        .reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }

  static List<WeightRecord> get weightHistory {
    final list = weightRecords.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static Future<void> addWeight(double kg) async {
    final now = DateTime.now();
    final id = 'weight-${now.millisecondsSinceEpoch}';
    final record = WeightRecord(id: id, date: now, weightKg: kg);
    await weightRecords.put(id, record);
    unawaited(FirestoreService.addWeightRecord(record));
  }

  // ── Skip helpers ──────────────────────────────────────────────────────────

  static Future<void> skipSession(String sessionId, int reasonIndex) async {
    final now = DateTime.now();
    final id = 'skip-$sessionId-${now.millisecondsSinceEpoch}';
    final record = SkipRecord(
      id: id,
      date: now,
      sessionId: sessionId,
      reasonIndex: reasonIndex,
    );
    await skipRecords.put(id, record);
    unawaited(FirestoreService.addSkipRecord(record));
  }
}
