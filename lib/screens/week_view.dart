import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/hive_service.dart';
import '../models/exercise.dart';
import '../models/training_session.dart';
import 'exercise_detail_view.dart';
import 'checkin_sheet.dart';

class WeekView extends StatefulWidget {
  const WeekView({super.key});

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  static const _green = Color(0xFF1D9E75);
  final _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  late int _selectedDay;
  String? _expandedSessionId;

  static const _dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().weekday;
  }

  DateTime get _today => DateTime.now();
  DateTime get _monday => _today.subtract(Duration(days: _today.weekday - 1));
  DateTime _dayDate(int weekday) => _monday.add(Duration(days: weekday - 1));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        HiveService.checkRecords.listenable(),
        HiveService.sessions.listenable(),
        HiveService.skipRecords.listenable(),
      ]),
      builder: (context, _) {
        final sessionIds = HiveService.currentWeekSessionIds();
        final completed = HiveService.sessionsCompletedThisWeek();
        final target = HiveService.currentWeekTarget();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => CheckinSheet.show(context),
            backgroundColor: _green,
            icon: const Icon(Icons.mood_rounded, color: Colors.white),
            label: Text('¿Cómo estoy?',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildDayPills(),
                _buildProgressBar(completed, target),
                Expanded(child: _buildContent(sessionIds)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final cycleName = HiveService.cycleName;
    final daysLeft = HiveService.daysUntilCycleEnd();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Text(
            'Esta semana',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          if (cycleName != null) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: daysLeft <= 3
                      ? const Color(0xFFFFF3CD)
                      : const Color(0xFFE8F5EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  daysLeft > 0
                      ? '$daysLeft días · partido'
                      : daysLeft == 0
                          ? '¡Hoy es el partido!'
                          : cycleName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: daysLeft <= 3
                        ? const Color(0xFF8B6E00)
                        : _green,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Day pills ─────────────────────────────────────────────────────────────

  Widget _buildDayPills() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(7, (i) {
          final weekday = i + 1;
          final date = _dayDate(weekday);
          final isToday = _today.weekday == weekday;
          final isSelected = _selectedDay == weekday;
          final hasActivity = HiveService.hasActivityOnDate(date);
          final dayType = HiveService.getDayType(date);

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 6 ? 5 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _selectedDay = weekday),
                child: _DayPill(
                  label: _dayLabels[i],
                  isToday: isToday,
                  isSelected: isSelected,
                  hasActivity: hasActivity,
                  isRest: dayType == 'descanso',
                  isGameDay: dayType == 'partido',
                  green: _green,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────

  Widget _buildProgressBar(int completed, int target) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sesiones esta semana',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF888888),
                ),
              ),
              Text(
                '$completed / $target',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: completed >= target ? _green : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: target > 0 ? (completed / target).clamp(0.0, 1.0) : 0,
              minHeight: 6,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(
                completed >= target ? _green : const Color(0xFF1D9E75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _buildContent(List<String> sessionIds) {
    final date = _dayDate(_selectedDay);
    final dayType = HiveService.getDayType(date);
    final dayName = _dayNames[_selectedDay - 1];
    return Column(
      children: [
        _buildDayTypeChips(date, dayType),
        Expanded(
          child: switch (dayType) {
            'descanso' => _buildRestDayCard(dayName),
            'partido'  => _buildGameDayCard(dayName),
            _          => _buildPoolSessions(sessionIds),
          },
        ),
      ],
    );
  }

  Widget _buildDayTypeChips(DateTime date, String current) {
    const types = [
      ('entrenamiento', 'Entreno', Icons.fitness_center_rounded),
      ('descanso', 'Descanso', Icons.bedtime_rounded),
      ('partido', 'Partido', Icons.sports_soccer_rounded),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: types.map((t) {
          final isSelected = current == t.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: isSelected ? null : () async {
                await HiveService.setDayType(date, t.$1);
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? _green : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$3, size: 13,
                        color: isSelected ? Colors.white : const Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Text(t.$2,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF888888),
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Pool sessions ─────────────────────────────────────────────────────────

  Widget _buildPoolSessions(List<String> sessionIds) {
    final poolSessions = sessionIds
        .map((id) => HiveService.sessions.get(id))
        .whereType<TrainingSession>()
        .toList();

    if (poolSessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Sin sesiones para esta semana.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFAAAAAA),
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      children: poolSessions.map((session) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPoolCard(session),
        );
      }).toList(),
    );
  }

  Widget _buildPoolCard(TrainingSession session) {
    final isDone = HiveService.isSessionDoneThisWeek(session.id);
    final isSkipped = HiveService.isSkippedThisWeek(session.id);
    final isExpanded = _expandedSessionId == session.id;

    final exercises = session.exerciseIds
        .map((id) => HiveService.exercises.get(id))
        .whereType<Exercise>()
        .toList();

    final checkedCount = exercises
        .where((ex) => HiveService.isCheckedToday(ex.id, session.id))
        .length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDone
            ? Border.all(color: _green, width: 1.5)
            : isSkipped
                ? Border.all(
                    color: const Color(0xFFFFCC02).withValues(alpha: 0.6),
                    width: 1)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Session header ───────────────────────────────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: isDone
                ? null
                : () => setState(() {
                      _expandedSessionId =
                          isExpanded ? null : session.id;
                    }),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDone
                          ? _green
                          : isSkipped
                              ? const Color(0xFFFFF8E1)
                              : const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone
                          ? Icons.check
                          : isSkipped
                              ? Icons.pause_circle_outline
                              : Icons.sports_soccer_outlined,
                      size: 18,
                      color: isDone
                          ? Colors.white
                          : isSkipped
                              ? const Color(0xFFF9A825)
                              : const Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDone
                                ? const Color(0xFF888888)
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          session.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFAAAAAA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDone)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Completada',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _green,
                        ),
                      ),
                    )
                  else
                    Icon(
                      isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: const Color(0xFFCCCCCC),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),

          // ── Action buttons (collapsed, not done) ─────────────────────────
          if (!isDone && !isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(
                            () => _expandedSessionId = session.id),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: Text(
                          'Empezar',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () =>
                          _showSkipSheet(context, session.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF888888),
                        side: const BorderSide(color: Color(0xFFE8E8E8)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        'Hoy no pude',
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Expanded: exercise checklist ─────────────────────────────────
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 4, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$checkedCount / ${exercises.length} ejercicios',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFAAAAAA),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _expandedSessionId = null),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF888888),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                    child: Text(
                      'Cerrar',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercises.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 52,
                endIndent: 16,
                color: Color(0xFFF5F5F5),
              ),
              itemBuilder: (context, i) {
                final ex = exercises[i];
                final isDoneEx =
                    HiveService.isCheckedToday(ex.id, session.id);
                return _ExerciseCheckItem(
                  exercise: ex,
                  isDone: isDoneEx,
                  green: _green,
                  onToggle: () async {
                    await HiveService.toggleCheckToday(
                        ex.id, session.id);
                    setState(() {});
                  },
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ExerciseDetailView(exerciseId: ex.id),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // ── Skip sheet ────────────────────────────────────────────────────────────

  void _showSkipSheet(BuildContext context, String sessionId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SkipSheet(
        onConfirm: (reasonIndex) async {
          await HiveService.skipSession(sessionId, reasonIndex);
          if (mounted) setState(() {});
        },
      ),
    );
  }

  // ── Rest day (Saturday) ───────────────────────────────────────────────────

  Widget _buildRestDayCard(String dayName) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dayLabel(dayName),
          const SizedBox(height: 4),
          Text(
            'Descanso',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 2),
          Text('Casa · Recuperación completa',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF888888))),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                            color: Color(0xFFF0FBF7),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.bedtime_rounded,
                            size: 36, color: Color(0xFF1D9E75)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tu cuerpo se adapta cuando descansa',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'El descanso es parte del entrenamiento. Aprovecha el sábado para recargar energía antes del partido del domingo.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF888888),
                          height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle('Qué hacer hoy'),
                    const SizedBox(height: 12),
                    _restTip(Icons.water_drop_outlined, 'Hidratación',
                        'Bebe 2-3 litros de agua a lo largo del día.'),
                    _restTip(Icons.restaurant_outlined, 'Alimentación',
                        'Prioriza carbohidratos y proteínas: pasta, arroz, pollo, huevos.'),
                    _restTip(Icons.self_improvement_outlined,
                        'Movilidad opcional',
                        'Si lo notas necesario, 10 min de foam roller o estiramientos suaves.'),
                    _restTip(Icons.directions_walk_outlined,
                        'Actividad ligera',
                        'Un paseo corto está bien. Nada de cargas intensas.'),
                    _restTip(Icons.bedtime_outlined, 'Sueño',
                        'Intenta dormir 7-8 horas esta noche para llegar fresco al partido.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _restTip(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFF0FBF7),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: _green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 2),
                Text(body,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF888888),
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Game day (Sunday) ─────────────────────────────────────────────────────

  Widget _buildGameDayCard(String dayName) {
    final daysLeft = HiveService.daysUntilCycleEnd();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dayLabel(dayName),
          const SizedBox(height: 4),
          Text(
            daysLeft == 0 ? '¡Hoy es el partido!' : 'Día de Partido',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 2),
          Text('Campo · Competición',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF888888))),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _gameDayRoutineCard(),
                  const SizedBox(height: 12),
                  _warmUpCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameDayRoutineCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.wb_sunny_rounded,
                    size: 18, color: Color(0xFFF9A825)),
              ),
              const SizedBox(width: 10),
              Text('Rutina del día',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 16),
          _timelineItem('Mañana', Icons.free_breakfast_outlined,
              'Desayuno rico en carbohidratos: avena, tostadas integrales o arroz.'),
          _timelineItem('2-3 h antes', Icons.water_drop_outlined,
              'Hidratación activa. Come algo ligero si el partido es tarde: banana, arroz con pollo.'),
          _timelineItem('1 h antes', Icons.directions_run_outlined,
              'Llega al campo con tiempo. Sin redes sociales, música que te active.'),
          _timelineItem('30 min antes', Icons.fitness_center_outlined,
              'Calentamiento progresivo (ver abajo). Entra en calor sin agotarte.'),
          _timelineItem('Partido', Icons.sports_soccer_outlined,
              'Aplica lo trabajado. Confía en tu preparación.',
              isLast: true),
        ],
      ),
    );
  }

  Widget _timelineItem(String time, IconData icon, String description,
      {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    color: Color(0xFFF0FBF7), shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: _green),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: const Color(0xFFE8E8E8),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(time,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _green,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF555555),
                          height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warmUpCard() {
    final warmUpItems = [
      _WarmUpStep('Trote suave', 5, 'Arranca sin exigencia para elevar temperatura muscular.'),
      _WarmUpStep('Movilidad dinámica', 4, 'Círculos de cadera, rodillas y tobillos en movimiento.'),
      _WarmUpStep('Skipping + talones al glúteo', 3, '2 series de 20m. Activa cuádriceps e isquiotibiales.'),
      _WarmUpStep('Estiramientos dinámicos', 4, 'Balanceos de piernas, estocadas caminando, rotaciones de tronco.'),
      _WarmUpStep('Toques de activación con balón', 4, 'Toques suaves, pases cortos, conducciones. Sin presión.'),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.directions_run_rounded,
                    size: 18, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calentamiento pre-partido',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A))),
                    Text('20 min · Progresivo',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF888888))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...warmUpItems.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            return Padding(
              padding:
                  EdgeInsets.only(bottom: i < warmUpItems.length - 1 ? 12 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration:
                        const BoxDecoration(color: _green, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${i + 1}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(step.name,
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1A1A))),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFF0FBF7),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text('${step.minutes} min',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _green)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(step.description,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF888888),
                                height: 1.4)),
                      ],
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _dayLabel(String name) {
    final dayIndex = ['Lunes', 'Martes', 'Miércoles',
            'Jueves', 'Viernes', 'Sábado', 'Domingo']
        .indexOf(name) + 1;
    final isToday = _today.weekday == dayIndex;
    return Text(
      isToday ? 'Hoy · $name' : name,
      style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF888888)),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF888888),
            letterSpacing: 0.5));
  }
}

// ── Skip Sheet ────────────────────────────────────────────────────────────────

class _SkipSheet extends StatefulWidget {
  final Future<void> Function(int reasonIndex) onConfirm;
  const _SkipSheet({required this.onConfirm});

  @override
  State<_SkipSheet> createState() => _SkipSheetState();
}

class _SkipSheetState extends State<_SkipSheet> {
  static const _green = Color(0xFF1D9E75);
  int? _selected;
  bool _saving = false;

  static const _reasons = [
    (index: 0, label: 'Descanso planeado', sub: 'Decidiste descansar conscientemente', icon: Icons.bedtime_outlined),
    (index: 1, label: 'Nutrición personal', sub: 'Tiempo de calidad con personas importantes', icon: Icons.people_outline),
    (index: 2, label: 'Imprevisto / fuerza mayor', sub: 'Algo fuera de tu control', icon: Icons.flash_on_outlined),
    (index: 3, label: 'Energía baja / desánimo', sub: 'Un día difícil — pasa, no te define', icon: Icons.battery_1_bar_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Por qué hoy no pudiste?',
              style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text('Esto queda guardado solo para tu contexto. No hay juicio.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF888888))),
          const SizedBox(height: 16),
          for (final r in _reasons) ...[
            GestureDetector(
              onTap: () => setState(() => _selected = r.index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _selected == r.index
                      ? _green.withValues(alpha: 0.08)
                      : const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selected == r.index
                        ? _green
                        : const Color(0xFFEEEEEE),
                    width: _selected == r.index ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(r.icon,
                        size: 20,
                        color: _selected == r.index
                            ? _green
                            : const Color(0xFF888888)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.label,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _selected == r.index
                                      ? _green
                                      : const Color(0xFF1A1A1A))),
                          Text(r.sub,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFFAAAAAA))),
                        ],
                      ),
                    ),
                    if (_selected == r.index)
                      const Icon(Icons.check_circle,
                          color: _green, size: 18),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selected == null || _saving)
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      final nav = Navigator.of(context);
                      await widget.onConfirm(_selected!);
                      nav.pop();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Registrar',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day Pill ──────────────────────────────────────────────────────────────────

class _DayPill extends StatelessWidget {
  final String label;
  final bool isToday;
  final bool isSelected;
  final bool hasActivity;
  final bool isRest;
  final bool isGameDay;
  final Color green;

  const _DayPill({
    required this.label,
    required this.isToday,
    required this.isSelected,
    required this.hasActivity,
    required this.isRest,
    required this.isGameDay,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isToday && isSelected) {
      bgColor = green;
      borderColor = green;
      textColor = Colors.white;
    } else if (isSelected) {
      bgColor = green.withValues(alpha: 0.12);
      borderColor = green;
      textColor = green;
    } else if (isRest) {
      bgColor = const Color(0xFFF5F5F5);
      borderColor = const Color(0xFFE8E8E8);
      textColor = const Color(0xFF999999);
    } else if (isGameDay) {
      bgColor = const Color(0xFFFFF8E1);
      borderColor = const Color(0xFFFFCC02);
      textColor = const Color(0xFF8B6E00);
    } else {
      bgColor = Colors.white;
      borderColor = const Color(0xFFE8E8E8);
      textColor = const Color(0xFF1A1A1A);
    }

    Widget indicator;
    if (isRest) {
      indicator = Icon(Icons.bedtime_rounded,
          size: 10, color: const Color(0xFFBBBBBB));
    } else if (isGameDay) {
      indicator = const Icon(Icons.sports_soccer, size: 10, color: Color(0xFFFFCC02));
    } else if (hasActivity) {
      indicator = Icon(Icons.check_circle,
          size: 12,
          color: (isToday && isSelected) ? Colors.white : green);
    } else {
      indicator = Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (isToday && isSelected)
              ? Colors.white.withValues(alpha: 0.5)
              : const Color(0xFFDDDDDD),
        ),
      );
    }

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
          const SizedBox(height: 2),
          indicator,
        ],
      ),
    );
  }
}

// ── Exercise Check Item ───────────────────────────────────────────────────────

class _ExerciseCheckItem extends StatelessWidget {
  final Exercise exercise;
  final bool isDone;
  final Color green;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _ExerciseCheckItem({
    required this.exercise,
    required this.isDone,
    required this.green,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? green : Colors.transparent,
                  border: Border.all(
                      color: isDone ? green : const Color(0xFFCCCCCC),
                      width: 2),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? const Color(0xFFAAAAAA)
                              : const Color(0xFF1A1A1A),
                          decoration:
                              isDone ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: 2),
                  Text('${exercise.durationMinutes} min',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFFAAAAAA))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFCCCCCC), size: 18),
          ],
        ),
      ),
    );
  }
}

class _WarmUpStep {
  final String name;
  final int minutes;
  final String description;
  _WarmUpStep(this.name, this.minutes, this.description);
}
