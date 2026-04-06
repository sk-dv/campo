import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campo/data/hive_service.dart';
import 'package:campo/data/firestore_service.dart';
import 'package:campo/models/day_record.dart';

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
            const SizedBox(height: 16),
            _buildCoachSection(),
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
    final weeks = cycle['weeks'] as List<dynamic>?;
    if (weeks == null) return const SizedBox.shrink();

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

  // ── Coach logs ──────────────────────────────────────────────────────────────

  Widget _buildCoachSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FirestoreService.fetchCoachLogs(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Card(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final logs = snap.data ?? [];

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_rounded, size: 18, color: _green),
                  const SizedBox(width: 8),
                  Text('Consejos del coach',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A))),
                ],
              ),
              const SizedBox(height: 12),
              if (logs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Aún no has hablado con el coach. '
                    'Usa "¿Cómo estoy?" para empezar.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFFAAAAAA)),
                  ),
                )
              else
                ...logs.map((l) => _buildCoachItem(context, l)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoachItem(BuildContext context, Map<String, dynamic> log) {
    final response = log['response'] as String? ?? '';
    final ts = log['createdAt'];
    DateTime? date;
    if (ts is Timestamp) date = ts.toDate();
    final checkin = log['checkin'] as Map<String, dynamic>?;

    // New logs: 'checkin' field. Old logs: parse from 'prompt'.
    final int? energy;
    final dynamic sleep;
    final String? note;
    if (checkin != null) {
      energy = checkin['energyLevel'] as int?;
      sleep = checkin['sleepHours'];
      note = checkin['note'] as String?;
    } else {
      final prompt = log['prompt'] as String? ?? '';
      final eM = RegExp(r'energía (\d+)/10').firstMatch(prompt);
      final sM = RegExp(r'sueño ([\d.]+)h').firstMatch(prompt);
      // Note is the quoted text after the sleep line
      final nM =
          RegExp(r'sueño [\d.]+h\. "([^"]*)"').firstMatch(prompt);
      energy = eM != null ? int.tryParse(eM.group(1)!) : null;
      sleep = sM != null ? double.tryParse(sM.group(1)!) : null;
      note = nM?.group(1);
    }

    return GestureDetector(
      onTap: () => _showCoachDetail(
        context,
        date: date,
        energy: energy,
        sleep: sleep,
        note: note,
        response: response,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (date != null)
                  Text(
                    _formatDate(date),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFAAAAAA)),
                  ),
                if (energy != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '· Energía $energy/10',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFAAAAAA)),
                  ),
                ],
                if (sleep != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '· ${sleep}h sueño',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFAAAAAA)),
                  ),
                ],
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: Color(0xFFCCCCCC)),
              ],
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '"$note"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF888888)),
              ),
            ],
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _green.withValues(alpha: 0.15)),
              ),
              child: Text(
                response,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: const Color(0xFF333333)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCoachDetail(
    BuildContext context, {
    DateTime? date,
    int? energy,
    dynamic sleep,
    String? note,
    required String response,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: ListView(
            controller: controller,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sports_rounded,
                        size: 18, color: _green),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    date != null ? _formatDate(date) : 'Coach',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A)),
                  ),
                ],
              ),
              // Check-in stats
              if (energy != null || sleep != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (energy != null)
                      _statChip('Energía $energy/10'),
                    if (energy != null && sleep != null)
                      const SizedBox(width: 8),
                    if (sleep != null)
                      _statChip('${sleep}h sueño'),
                  ],
                ),
              ],
              // Note
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Lo que dijiste',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF888888)),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: const Color(0xFF333333)),
                  ),
                ),
              ],
              // Response
              const SizedBox(height: 16),
              Text(
                'Respuesta del coach',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF888888)),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _green.withValues(alpha: 0.2)),
                ),
                child: Text(
                  response,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.6,
                      color: const Color(0xFF1A1A1A)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _green),
        ),
      );

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
