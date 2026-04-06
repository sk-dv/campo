import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:campo/data/backup_service.dart';
import 'package:campo/data/hive_service.dart';
import 'package:campo/models/exercise.dart';
import 'exercise_detail_view.dart';

class ExercisesListView extends StatelessWidget {
  static const _green = Color(0xFF1D9E75);

  const ExercisesListView({super.key});

  void _showBackupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _BackupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ejercicios',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cloud_outlined),
                    color: const Color(0xFF888888),
                    tooltip: 'Backup',
                    onPressed: () => _showBackupSheet(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: HiveService.exercises.listenable(),
                builder: (context, box, _) {
                  final exercises = HiveService.exercises.values.toList();
                  final grouped = _groupByCategory(exercises);

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: grouped.entries.map((entry) {
                      return _CategorySection(
                        category: entry.key,
                        exercises: entry.value,
                        green: _green,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<ExerciseCategory, List<Exercise>> _groupByCategory(
      List<Exercise> exercises) {
    final map = <ExerciseCategory, List<Exercise>>{};
    for (final cat in ExerciseCategory.values) {
      final list = exercises.where((e) => e.category == cat).toList();
      if (list.isNotEmpty) map[cat] = list;
    }
    return map;
  }
}

class _CategorySection extends StatelessWidget {
  final ExerciseCategory category;
  final List<Exercise> exercises;
  final Color green;

  const _CategorySection({
    required this.category,
    required this.exercises,
    required this.green,
  });

  String get _categoryLabel {
    switch (category) {
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
    switch (category) {
      case ExerciseCategory.tecnica:
        return const Color(0xFF3B82F6);
      case ExerciseCategory.fisico:
        return const Color(0xFFEF4444);
      case ExerciseCategory.movilidad:
        return green;
      case ExerciseCategory.mental:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _categoryLabel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF888888),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exercises.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Color(0xFFF0F0F0),
            ),
            itemBuilder: (context, index) {
              final ex = exercises[index];
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseDetailView(exerciseId: ex.id),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: Text(
                  ex.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                subtitle: Text(
                  '${ex.durationMinutes} min',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFAAAAAA),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFCCCCCC),
                  size: 18,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Backup sheet ─────────────────────────────────────────────────────────────

class _BackupSheet extends StatefulWidget {
  const _BackupSheet();

  @override
  State<_BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<_BackupSheet> {
  static const _green = Color(0xFF1D9E75);
  bool _loading = false;
  String? _message;

  Future<void> _export() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await BackupService.exportBackup();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _message = 'Error al exportar. Intenta de nuevo.';
        });
      }
    }
  }

  Future<void> _import() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final result = await BackupService.importBackup();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = switch (result) {
          'ok' => '¡Datos restaurados correctamente!',
          'cancelled' => null,
          'invalid' => 'Archivo inválido. Selecciona un backup de Campo.',
          _ => 'Error al importar.',
        };
      });
      if (result == 'ok' && mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _message = 'Error al importar. Intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backup',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Guarda o restaura tus ejercicios e imágenes.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                color: _green,
                strokeWidth: 2.5,
              ),
            )
          else ...[
            _BackupButton(
              icon: Icons.upload_rounded,
              label: 'Exportar',
              sublabel: 'Guardar en iCloud Drive u otro lugar',
              color: _green,
              onTap: _export,
            ),
            const SizedBox(height: 12),
            _BackupButton(
              icon: Icons.download_rounded,
              label: 'Importar',
              sublabel: 'Restaurar desde un archivo .zip',
              color: const Color(0xFF3B82F6),
              onTap: _import,
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(
              _message!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _message!.contains('¡')
                    ? _green
                    : const Color(0xFFEF4444),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BackupButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _BackupButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }
}
