import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'data/hive_service.dart';
import 'data/firestore_service.dart';
import 'screens/week_view.dart';
import 'screens/exercises_list_view.dart';
import 'screens/historial_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await HiveService.init();
  try {
    await FirestoreService.init();
    await _migrateToFirestoreIfNeeded();
    await _syncActiveCycleFromFirestore();
  } catch (_) {
    // Firebase no disponible — offline con Hive
  }
  runApp(const CampoApp());
}

// Lee el ciclo de Firestore (config/active_cycle) y lo
// guarda en Hive. Permite actualizar el ciclo desde
// Firebase Console sin hacer rebuild.
Future<void> _syncActiveCycleFromFirestore() async {
  final json = await FirestoreService.fetchActiveCycle();
  if (json == null) return;
  await Hive.box(HiveService.metaBox).put('active_cycle', json);
}

Future<void> _migrateToFirestoreIfNeeded() async {
  final meta = Hive.box(HiveService.metaBox);
  if (meta.get('firestore_migrated_v1') == true) return;

  for (final ex in HiveService.exercises.values) {
    await FirestoreService.upsertExercise(ex);
  }
  for (final s in HiveService.sessions.values) {
    await FirestoreService.upsertSession(s);
  }
  for (final w in HiveService.weightRecords.values) {
    await FirestoreService.addWeightRecord(w);
  }
  for (final s in HiveService.skipRecords.values) {
    await FirestoreService.addSkipRecord(s);
  }

  // Reconstruir sesiones completadas desde check_records
  final Map<String, Set<String>> exercisesByKey = {};
  for (final r in HiveService.checkRecords.values) {
    if (!r.isDone) continue;
    final ws = _weekStartStr(r.completedDate);
    final key = '${r.sessionId}|$ws';
    exercisesByKey.putIfAbsent(key, () => {}).add(r.exerciseId);
  }
  for (final entry in exercisesByKey.entries) {
    final parts = entry.key.split('|');
    await FirestoreService.recordCompletedSession(
      sessionId: parts[0],
      weekStart: parts[1],
      exerciseIds: entry.value.toList(),
    );
  }

  await meta.put('firestore_migrated_v1', true);
}

String _weekStartStr(DateTime date) {
  final monday = date.subtract(Duration(days: date.weekday - 1));
  return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
}

class CampoApp extends StatelessWidget {
  const CampoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D9E75),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _green = Color(0xFF1D9E75);

  final _screens = const [
    WeekView(),
    ExercisesListView(),
    HistorialView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Semana',
                  isSelected: _currentIndex == 0,
                  green: _green,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.fitness_center_rounded,
                  label: 'Ejercicios',
                  isSelected: _currentIndex == 1,
                  green: _green,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Historial',
                  isSelected: _currentIndex == 2,
                  green: _green,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color green;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.green,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? green : const Color(0xFFBBBBBB),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? green : const Color(0xFFBBBBBB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
