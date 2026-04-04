import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../data/hive_service.dart';
import '../models/exercise.dart';

class ExerciseEditView extends StatefulWidget {
  final String exerciseId;

  const ExerciseEditView({super.key, required this.exerciseId});

  @override
  State<ExerciseEditView> createState() => _ExerciseEditViewState();
}

class _ExerciseEditViewState extends State<ExerciseEditView> {
  static const _green = Color(0xFF1D9E75);

  late Exercise _exercise;
  late TextEditingController _nameCtrl;
  late TextEditingController _durationCtrl;
  late ExerciseCategory _category;
  late List<TextEditingController> _stepCtrls;
  late List<String> _imagePaths;
  late List<int> _imageTimerSeconds;
  late int _defaultTimerSeconds;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _exercise = HiveService.exercises.get(widget.exerciseId)!;
    _nameCtrl = TextEditingController(text: _exercise.name);
    _durationCtrl =
        TextEditingController(text: '${_exercise.durationMinutes}');
    _category = _exercise.category;
    _stepCtrls = _exercise.instructions
        .map((s) => TextEditingController(text: s))
        .toList();
    _imagePaths = List<String>.from(_exercise.imagePaths);
    final savedTimers = _exercise.imageTimerSeconds;
    _imageTimerSeconds = List<int>.generate(
      _imagePaths.length,
      (i) => i < savedTimers.length ? savedTimers[i] : 0,
    );
    _defaultTimerSeconds = _exercise.defaultTimerSeconds;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _durationCtrl.dispose();
    for (final c in _stepCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Editar ejercicio',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _green,
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text(
                    'Guardar',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: _green,
                    ),
                  ),
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            'Información básica',
            Column(
              children: [
                _buildTextField(
                  controller: _nameCtrl,
                  label: 'Nombre',
                  hint: 'Nombre del ejercicio',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _durationCtrl,
                  label: 'Duración (min)',
                  hint: '10',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildCategoryPicker(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Instrucciones',
            Column(
              children: [
                ...List.generate(_stepCtrls.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _stepCtrls[i],
                            style: GoogleFonts.inter(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Paso ${i + 1}',
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFFBBBBBB),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE8E8E8),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE8E8E8),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: _green,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: _stepCtrls.length > 1
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Color(0xFFCCCCCC),
                                        size: 20,
                                      ),
                                      onPressed: () => _removeStep(i),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add, color: _green, size: 18),
                  label: Text(
                    'Añadir paso',
                    style: GoogleFonts.inter(
                      color: _green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Imágenes',
            Column(
              children: [
                // Timer general
                _buildDefaultTimerRow(),
                const SizedBox(height: 16),
                if (_imagePaths.isNotEmpty) ...[
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 12),
                  Text(
                    'Temporizador por imagen (opcional)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFAAAAAA),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_imagePaths.length, _buildImageListItem),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined,
                            size: 18),
                        label: Text(
                          'Galería',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _green,
                          side: const BorderSide(color: _green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined,
                            size: 18),
                        label: Text(
                          'Cámara',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _green,
                          side: const BorderSide(color: _green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDefaultTimerRow() {
    final hasTimer = _defaultTimerSeconds > 0;
    final minutes = _defaultTimerSeconds ~/ 60;
    final seconds = _defaultTimerSeconds % 60;

    return Row(
      children: [
        const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF888888)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Temporizador general',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'Se aplica a imágenes sin tiempo específico',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () async {
            final result = await showDialog<int>(
              context: context,
              builder: (_) =>
                  _TimerDialog(initialSeconds: _defaultTimerSeconds),
            );
            if (result != null) {
              setState(() => _defaultTimerSeconds = result);
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hasTimer
                  ? _green.withValues(alpha: 0.1)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasTimer ? _green : const Color(0xFFE8E8E8),
              ),
            ),
            child: Text(
              hasTimer
                  ? '$minutes:${seconds.toString().padLeft(2, '0')}'
                  : 'Añadir',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasTimer ? _green : const Color(0xFFBBBBBB),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageListItem(int index) {
    final timerSec = _imageTimerSeconds[index];
    final hasTimer = timerSec > 0;
    final minutes = timerSec ~/ 60;
    final seconds = timerSec % 60;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_imagePaths[index]),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: const Color(0xFFE8E8E8),
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFFCCCCCC),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foto ${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showTimerDialog(index),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: hasTimer ? _green : const Color(0xFFBBBBBB),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasTimer
                            ? '$minutes:${seconds.toString().padLeft(2, '0')}'
                            : 'Añadir temporizador',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: hasTimer ? _green : const Color(0xFFBBBBBB),
                          fontWeight: hasTimer
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFFCCCCCC),
              size: 22,
            ),
            onPressed: () => _removeImage(index),
          ),
        ],
      ),
    );
  }

  Future<void> _showTimerDialog(int index) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _TimerDialog(initialSeconds: _imageTimerSeconds[index]),
    );
    if (result != null) {
      setState(() => _imageTimerSeconds[index] = result);
    }
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
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
          child: child,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: const Color(0xFFBBBBBB)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoría',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: ExerciseCategory.values.map((cat) {
            final isSelected = _category == cat;
            final label = switch (cat) {
              ExerciseCategory.tecnica => 'Técnica',
              ExerciseCategory.fisico => 'Físico',
              ExerciseCategory.movilidad => 'Movilidad',
              ExerciseCategory.mental => 'Mental',
            };
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? _green : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _green : const Color(0xFFE8E8E8),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _addStep() {
    setState(() {
      _stepCtrls.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      _stepCtrls[index].dispose();
      _stepCtrls.removeAt(index);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
      _imageTimerSeconds.removeAt(index);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final appDir = await getApplicationDocumentsDirectory();
    final destDir = p.join(appDir.path, 'exercise_images');
    await Directory(destDir).create(recursive: true);

    if (source == ImageSource.gallery) {
      final picked = await picker.pickMultiImage(imageQuality: 85);
      if (picked.isEmpty) return;
      final newPaths = <String>[];
      for (final file in picked) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${newPaths.length}.jpg';
        final destPath = p.join(destDir, fileName);
        await File(file.path).copy(destPath);
        newPaths.add(destPath);
      }
      setState(() {
        _imagePaths.addAll(newPaths);
        _imageTimerSeconds.addAll(List.filled(newPaths.length, 0));
      });
    } else {
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destPath = p.join(destDir, fileName);
      await File(picked.path).copy(destPath);
      setState(() {
        _imagePaths.add(destPath);
        _imageTimerSeconds.add(0);
      });
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final duration = int.tryParse(_durationCtrl.text.trim()) ?? 0;
    if (name.isEmpty || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _saving = true);

    _exercise.name = name;
    _exercise.durationMinutes = duration;
    _exercise.category = _category;
    _exercise.instructions =
        _stepCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    _exercise.imagePaths = _imagePaths;
    _exercise.imageTimerSeconds = _imageTimerSeconds;
    _exercise.defaultTimerSeconds = _defaultTimerSeconds;
    await _exercise.save();

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }
}

class _TimerDialog extends StatefulWidget {
  final int initialSeconds;

  const _TimerDialog({required this.initialSeconds});

  @override
  State<_TimerDialog> createState() => _TimerDialogState();
}

class _TimerDialogState extends State<_TimerDialog> {
  static const _green = Color(0xFF1D9E75);

  late TextEditingController _minCtrl;
  late TextEditingController _secCtrl;

  @override
  void initState() {
    super.initState();
    final min = widget.initialSeconds ~/ 60;
    final sec = widget.initialSeconds % 60;
    _minCtrl = TextEditingController(
      text: widget.initialSeconds > 0 ? '$min' : '',
    );
    _secCtrl = TextEditingController(
      text: widget.initialSeconds > 0 ? sec.toString().padLeft(2, '0') : '',
    );
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _secCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Temporizador',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TimeField(controller: _minCtrl, label: 'min'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ':',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          _TimeField(controller: _secCtrl, label: 'seg'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 0),
          child: Text(
            'Sin temporizador',
            style: GoogleFonts.inter(color: const Color(0xFF888888)),
          ),
        ),
        TextButton(
          onPressed: () {
            final min = int.tryParse(_minCtrl.text) ?? 0;
            final sec = (int.tryParse(_secCtrl.text) ?? 0).clamp(0, 59);
            Navigator.pop(context, min * 60 + sec);
          },
          child: Text(
            'Listo',
            style: GoogleFonts.inter(
              color: _green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _TimeField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 2,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '00',
              hintStyle: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFDDDDDD),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF1D9E75),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF888888),
          ),
        ),
      ],
    );
  }
}
