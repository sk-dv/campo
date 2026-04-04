import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/hive_service.dart';
import '../models/day_record.dart';

class HistorialView extends StatelessWidget {
  const HistorialView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        HiveService.weightRecords.listenable(),
        HiveService.checkRecords.listenable(),
        HiveService.skipRecords.listenable(),
        HiveService.dayRecords.listenable(),
      ]),
      builder: (context, _) => _HistorialContent(key: UniqueKey()),
    );
  }
}

class _HistorialContent extends StatelessWidget {
  static const _green = Color(0xFF1D9E75);
  static const _bg = Color(0xFFF5F5F5);

  const _HistorialContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Text(
              'Historial',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 20),
            _buildCycleSection(),
            const SizedBox(height: 16),
            _buildWeekSection(),
            const SizedBox(height: 16),
            _buildWeightSection(context),
            const SizedBox(height: 16),
            _buildTimelineSection(),
          ],
        ),
      ),
    );
  }

  // ── Ciclo activo ────────────────────────────────────────────────────────────

  Widget _buildCycleSection() {
    final cycle = HiveService.activeCycle;
    if (cycle == null) return const SizedBox.shrink();

    final name = cycle['name'] as String? ?? '';
    final daysLeft = HiveService.daysUntilCycleEnd();
    final weeks = cycle['weeks'] as List<dynamic>;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, size: 18, color: _green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$daysLeft días',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...weeks.asMap().entries.map((entry) {
            final week = entry.value as Map<String, dynamic>;
            final sessionIds = (week['sessionIds'] as List<dynamic>).cast<String>();
            final target = (week['target'] as int?) ?? sessionIds.length;
            final ws = DateTime.parse(week['weekStart'] as String);
            final done = sessionIds.where((id) => _isSessionDoneInWeek(id, ws)).length;
            final pct = target == 0 ? 0.0 : (done / target).clamp(0.0, 1.0);
            final label = _weekLabel(ws, entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF555555))),
                      Text('$done / $target',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _green)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE5E5E5),
                      valueColor: const AlwaysStoppedAnimation<Color>(_green),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isSessionDoneInWeek(String sessionId, DateTime weekStart) {
    final session = HiveService.sessions.get(sessionId);
    if (session == null || session.exerciseIds.isEmpty) return false;
    final weekEnd = weekStart.add(const Duration(days: 7));
    return session.exerciseIds.every((exId) {
      return HiveService.checkRecords.values.any((r) =>
          r.exerciseId == exId &&
          r.sessionId == sessionId &&
          r.isDone &&
          !r.completedDate.isBefore(weekStart) &&
          r.completedDate.isBefore(weekEnd));
    });
  }

  String _weekLabel(DateTime ws, int index) {
    const months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return 'Semana ${index + 1} · ${ws.day} ${months[ws.month]}';
  }

  // ── Semana actual ───────────────────────────────────────────────────────────

  Widget _buildWeekSection() {
    final done = HiveService.sessionsCompletedThisWeek();
    final target = HiveService.currentWeekTarget();
    final pct = target == 0 ? 0.0 : (done / target).clamp(0.0, 1.0);

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Esta semana',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) {
              final day = monday.add(Duration(days: i));
              final hasActivity = HiveService.hasActivityOnDate(day);
              final isToday = day.day == now.day &&
                  day.month == now.month &&
                  day.year == now.year;
              const dayLetters = ['L', 'M', 'X', 'J', 'V'];
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasActivity
                            ? _green
                            : isToday
                                ? _green.withValues(alpha: 0.15)
                                : const Color(0xFFE5E5E5),
                        border: isToday
                            ? Border.all(color: _green, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          hasActivity
                              ? Icons.check_rounded
                              : Icons.remove_rounded,
                          size: 16,
                          color: hasActivity
                              ? Colors.white
                              : const Color(0xFFAAAAAA),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(dayLetters[i],
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF888888))),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sesiones completadas',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF888888))),
              Text('$done / $target',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _green)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E5E5),
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
        ],
      ),
    );
  }

  // ── Peso ────────────────────────────────────────────────────────────────────

  Widget _buildWeightSection(BuildContext context) {
    final latest = HiveService.latestWeight;
    final history = HiveService.weightHistory;

    double? delta;
    if (history.length >= 2) {
      delta = history[0].weightKg - history[1].weightKg;
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Peso',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A))),
              TextButton.icon(
                onPressed: () => _showWeightDialog(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text('Registrar',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(foregroundColor: _green),
              ),
            ],
          ),
          if (latest != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  latest.weightKg.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A)),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('kg',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF888888))),
                ),
                if (delta != null) ...[
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: delta <= 0
                            ? _green.withValues(alpha: 0.12)
                            : const Color(0xFFFFEEEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: delta <= 0
                              ? _green
                              : const Color(0xFFCC3333),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Sin registros aún',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: const Color(0xFFAAAAAA))),
            ),
          if (history.length > 1) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...history.take(5).skip(1).map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(r.date),
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF888888))),
                      Text('${r.weightKg.toStringAsFixed(1)} kg',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF555555))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Registrar peso',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'ej. 66.5',
            suffix: Text('kg',
                style: GoogleFonts.inter(color: const Color(0xFF888888))),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: const Color(0xFF888888))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _green),
            onPressed: () async {
              final val = double.tryParse(
                  controller.text.replaceAll(',', '.'));
              if (val != null && val > 0) {
                await HiveService.addWeight(val);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text('Guardar',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Timeline ────────────────────────────────────────────────────────────────

  Widget _buildTimelineSection() {
    final days = HiveService.dayRecords.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (days.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actividad reciente',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          ...days.map((d) => _buildTimelineItem(d)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(DayRecord d) {
    final icon = _activityIcon(d.activityType);
    final label = _activityLabel(d.activityType);
    final color = d.completed
        ? (d.partialCompletion ? const Color(0xFFF59E0B) : _green)
        : const Color(0xFFAAAAAA);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A))),
                    Text(_formatDate(d.date),
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFFAAAAAA))),
                  ],
                ),
                if (d.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(d.notes,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF888888))),
                ],
                if (d.partialCompletion)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Completado parcialmente',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'partido':
        return Icons.sports_soccer_rounded;
      case 'correr':
        return Icons.directions_run_rounded;
      case 'futbol_tecnico':
        return Icons.sports_rounded;
      case 'fuerza':
        return Icons.fitness_center_rounded;
      case 'descanso':
        return Icons.hotel_rounded;
      default:
        return Icons.circle_rounded;
    }
  }

  String _activityLabel(String type) {
    switch (type) {
      case 'partido':
        return 'Partido';
      case 'correr':
        return 'Correr';
      case 'futbol_tecnico':
        return 'Técnica fútbol';
      case 'fuerza':
        return 'Fuerza';
      case 'descanso':
        return 'Descanso';
      default:
        return type;
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${d.day} ${months[d.month]}';
  }
}

// ── Card wrapper ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
