import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/hive_service.dart';
import '../models/exercise.dart';
import 'exercise_edit_view.dart';
import 'workout_player_view.dart';

class ExerciseDetailView extends StatelessWidget {
  final String exerciseId;

  const ExerciseDetailView({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService.exercises.listenable(keys: [exerciseId]),
      builder: (context, _, __) {
        final exercise = HiveService.exercises.get(exerciseId);
        if (exercise == null) {
          return const Scaffold(
            body: Center(child: Text('Ejercicio no encontrado')),
          );
        }
        return _ExerciseDetailContent(exercise: exercise);
      },
    );
  }
}

class _ExerciseDetailContent extends StatelessWidget {
  final Exercise exercise;
  static const _green = Color(0xFF1D9E75);

  const _ExerciseDetailContent({required this.exercise});

  String get _categoryLabel {
    switch (exercise.category) {
      case ExerciseCategory.tecnica:
        return 'Técnica';
      case ExerciseCategory.fisico:
        return 'Físico';
      case ExerciseCategory.movilidad:
        return 'Movilidad';
      case ExerciseCategory.mental:
        return 'Mental';
    }
  }

  Color get _categoryColor {
    switch (exercise.category) {
      case ExerciseCategory.tecnica:
        return const Color(0xFF3B82F6);
      case ExerciseCategory.fisico:
        return const Color(0xFFEF4444);
      case ExerciseCategory.movilidad:
        return _green;
      case ExerciseCategory.mental:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount =
        HiveService.completedThisWeekForExercise(exercise.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ExerciseEditView(exerciseId: exercise.id),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: exercise.imagePaths.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutPlayerView(exercise: exercise),
                ),
              ),
              backgroundColor: _green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                'Reproducir',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            exercise.name,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _CategoryTag(
                label: _categoryLabel,
                color: _categoryColor,
              ),
              const SizedBox(width: 8),
              _MetaChip(
                icon: Icons.timer_outlined,
                label: '${exercise.durationMinutes} min',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StatsRow(completedCount: completedCount, green: _green),
          const SizedBox(height: 24),
          if (exercise.imagePaths.isNotEmpty) ...[
            Text(
              'Imágenes',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            ...exercise.imagePaths.asMap().entries.map((entry) {
              final index = entry.key;
              final path = entry.value;
              final timerSec = index < exercise.imageTimerSeconds.length
                  ? exercise.imageTimerSeconds[index]
                  : 0;
              return _ImageListItem(
                path: path,
                index: index,
                timerSeconds: timerSec,
                green: _green,
              );
            }),
            const SizedBox(height: 24),
          ],
          Text(
            'Instrucciones',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          ...exercise.instructions.asMap().entries.map(
            (e) => _InstructionStep(
              number: e.key + 1,
              text: e.value,
              green: _green,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ImageListItem extends StatelessWidget {
  final String path;
  final int index;
  final int timerSeconds;
  final Color green;

  const _ImageListItem({
    required this.path,
    required this.index,
    required this.timerSeconds,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    final hasTimer = timerSeconds > 0;
    final minutes = timerSeconds ~/ 60;
    final seconds = timerSeconds % 60;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.file(
              File(path),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: double.infinity,
                height: 200,
                color: const Color(0xFFE8F5EF),
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: green.withValues(alpha: 0.4),
                ),
              ),
            ),
            if (hasTimer)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$minutes:${seconds.toString().padLeft(2, '0')}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF888888)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF888888),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int completedCount;
  final Color green;

  const _StatsRow({required this.completedCount, required this.green});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.bar_chart_rounded, color: green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sesiones completadas esta semana',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF444444),
              ),
            ),
          ),
          Text(
            '$completedCount',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: green,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int number;
  final String text;
  final Color green;

  const _InstructionStep({
    required this.number,
    required this.text,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF444444),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
