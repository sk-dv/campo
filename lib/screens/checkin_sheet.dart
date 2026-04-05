import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/firestore_service.dart';
import '../data/coach_service.dart';

enum _Phase { form, loading, response }

class CheckinSheet extends StatefulWidget {
  const CheckinSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CheckinSheet(),
    );
  }

  @override
  State<CheckinSheet> createState() => _CheckinSheetState();
}

class _CheckinSheetState extends State<CheckinSheet> {
  static const _green = Color(0xFF1D9E75);

  _Phase _phase = _Phase.form;
  double _energy = 7;
  final _sleepController = TextEditingController();
  final _noteController = TextEditingController();
  String _coachResponse = '';
  String? _error;

  @override
  void dispose() {
    _sleepController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save({required bool askCoach}) async {
    setState(() => _error = null);

    final sleep =
        double.tryParse(_sleepController.text.replaceAll(',', '.')) ?? 0;
    final note = _noteController.text.trim();
    final energy = _energy.round();

    await FirestoreService.saveDailyCheckin(
      date: _todayStr,
      energyLevel: energy,
      sleepHours: sleep,
      note: note,
    );

    if (!askCoach) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _phase = _Phase.loading);

    try {
      final text = await CoachService.askCoach(
        energyLevel: energy,
        sleepHours: sleep,
        note: note.isEmpty ? null : note,
      );
      if (mounted) {
        setState(() {
          _coachResponse = text;
          _phase = _Phase.response;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo conectar con el coach. Intenta más tarde.';
          _phase = _Phase.form;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: switch (_phase) {
          _Phase.form => _buildForm(),
          _Phase.loading => _buildLoading(),
          _Phase.response => _buildResponse(),
        },
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        const SizedBox(height: 20),
        Text('¿Cómo estás hoy?',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A))),
        const SizedBox(height: 24),

        // Energía
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Energía',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF555555))),
            Text('${_energy.round()} / 10',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _green)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: _energy,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: _green,
            inactiveColor: const Color(0xFFE5E5E5),
            onChanged: (v) => setState(() => _energy = v),
          ),
        ),
        const SizedBox(height: 16),

        // Sueño
        Text('Horas de sueño',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF555555))),
        const SizedBox(height: 8),
        _textField(
          controller: _sleepController,
          hint: 'ej. 7.5',
          suffix: 'h',
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),

        // Nota
        Text('Nota',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF555555))),
        const SizedBox(height: 8),
        _textField(
          controller: _noteController,
          hint: 'Cómo te sentiste, qué pasó hoy...',
          maxLines: 2,
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFFCC3333))),
        ],

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _save(askCoach: true),
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: Text('Hablar con coach',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => _save(askCoach: false),
            child: Text('Solo guardar',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF888888))),
          ),
        ),
      ],
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_green)),
            const SizedBox(height: 16),
            Text('Consultando al coach...',
                style: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFF888888))),
          ],
        ),
      ),
    );
  }

  // ── Response ──────────────────────────────────────────────────────────────

  Widget _buildResponse() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_rounded, size: 18, color: _green),
            ),
            const SizedBox(width: 10),
            Text('Tu coach',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: _green.withValues(alpha: 0.2)),
          ),
          child: Text(
            _coachResponse,
            style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.6,
                color: const Color(0xFF1A1A1A)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _handle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    String? suffix,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFE5E5E5)),
    );
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(color: const Color(0xFFAAAAAA)),
        suffixText: suffix,
        border: border,
        enabledBorder: border,
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _green, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
      ),
    );
  }
}
