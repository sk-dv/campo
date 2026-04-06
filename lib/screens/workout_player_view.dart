import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campo/models/exercise.dart';

class WorkoutPlayerView extends StatefulWidget {
  final Exercise exercise;

  const WorkoutPlayerView({super.key, required this.exercise});

  @override
  State<WorkoutPlayerView> createState() => _WorkoutPlayerViewState();
}

enum _Phase { preparing, running, manual, done }

class _ImageSlide {
  final String path;
  final int timerSeconds;
  const _ImageSlide({required this.path, required this.timerSeconds});
}

class _WorkoutPlayerViewState extends State<WorkoutPlayerView> {
  static const _green = Color(0xFF1D9E75);
  static const _prepSeconds = 5;

  late List<_ImageSlide> _slides;
  int _slideIndex = 0;
  _Phase _phase = _Phase.preparing;
  int _secondsLeft = _prepSeconds;
  bool _paused = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _buildSlides();
    if (_slides.isEmpty) return;
    _startPrep();
  }

  void _buildSlides() {
    final ex = widget.exercise;
    _slides = ex.imagePaths.asMap().entries.map((e) {
      final idx = e.key;
      final path = e.value;
      final specific =
          idx < ex.imageTimerSeconds.length ? ex.imageTimerSeconds[idx] : 0;
      final effective = specific > 0 ? specific : ex.defaultTimerSeconds;
      return _ImageSlide(path: path, timerSeconds: effective);
    }).toList();
  }

  void _startPrep() {
    _ticker?.cancel();
    setState(() {
      _phase = _Phase.preparing;
      _secondsLeft = _prepSeconds;
      _paused = false;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _playSound();
        _startRunning();
      }
    });
  }

  void _startRunning() {
    _ticker?.cancel();
    final slide = _slides[_slideIndex];
    if (slide.timerSeconds <= 0) {
      setState(() {
        _phase = _Phase.manual;
        _secondsLeft = 0;
      });
      return;
    }
    setState(() {
      _phase = _Phase.running;
      _secondsLeft = slide.timerSeconds;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _playSound(done: _slideIndex == _slides.length - 1);
        _advance();
      }
    });
  }

  void _advance() {
    if (_slideIndex < _slides.length - 1) {
      setState(() => _slideIndex++);
      _startPrep();
    } else {
      _ticker?.cancel();
      setState(() => _phase = _Phase.done);
    }
  }

  void _playSound({bool done = false}) {
    if (done) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 120), HapticFeedback.mediumImpact);
      SystemSound.play(SystemSoundType.alert);
    } else {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _togglePause() => setState(() => _paused = !_paused);

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            'Sin imágenes para reproducir',
            style: GoogleFonts.inter(color: Colors.white60),
          ),
        ),
      );
    }

    if (_phase == _Phase.done) {
      return _DoneScreen(
        exerciseName: widget.exercise.name,
        onRestart: () {
          setState(() {
            _slideIndex = 0;
            _paused = false;
          });
          _startPrep();
        },
        onExit: () => Navigator.pop(context),
      );
    }

    final slide = _slides[_slideIndex];
    final isPreparing = _phase == _Phase.preparing;
    final isRunning = _phase == _Phase.running;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_slideIndex + 1} / ${_slides.length}  ·  ${widget.exercise.name}',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
        ),
        actions: [
          if (isPreparing || isRunning)
            IconButton(
              icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
              color: Colors.white,
              onPressed: _togglePause,
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_slideIndex + 1) / _slides.length,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(_green),
            minHeight: 3,
          ),

          // Image area
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.file(
                  File(slide.path),
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white24,
                    size: 80,
                  ),
                ),
                if (isPreparing) _PrepOverlay(secondsLeft: _secondsLeft),
              ],
            ),
          ),

          // Bottom controls
          _BottomBar(
            phase: _phase,
            paused: _paused,
            secondsLeft: _secondsLeft,
            timerSeconds: slide.timerSeconds,
            onSkip: _advance,
            onTogglePause: _togglePause,
          ),
        ],
      ),
    );
  }
}

// ── Prep overlay ────────────────────────────────────────────────────────────

class _PrepOverlay extends StatelessWidget {
  final int secondsLeft;
  const _PrepOverlay({required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Prepárate',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: secondsLeft / 5,
                  strokeWidth: 6,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF1D9E75),
                  ),
                ),
                Text(
                  '$secondsLeft',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final _Phase phase;
  final bool paused;
  final int secondsLeft;
  final int timerSeconds;
  final VoidCallback onSkip;
  final VoidCallback onTogglePause;

  static const _green = Color(0xFF1D9E75);

  const _BottomBar({
    required this.phase,
    required this.paused,
    required this.secondsLeft,
    required this.timerSeconds,
    required this.onSkip,
    required this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = phase == _Phase.running;

    return Container(
      color: const Color(0xFF111111),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          // Timer ring (left)
          SizedBox(
            width: 72,
            height: 72,
            child: isRunning
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: timerSeconds > 0
                            ? secondsLeft / timerSeconds
                            : 0,
                        strokeWidth: 5,
                        backgroundColor: Colors.white12,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_green),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (paused)
                            Text(
                              'pausado',
                              style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 9,
                              ),
                            ),
                        ],
                      ),
                    ],
                  )
                : const SizedBox(),
          ),

          const Spacer(),

          // Skip button (right)
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white54,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  phase == _Phase.preparing ? 'Saltar prep' : 'Siguiente',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.skip_next, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Done screen ───────────────────────────────────────────────────────────────

class _DoneScreen extends StatelessWidget {
  final String exerciseName;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  static const _green = Color(0xFF1D9E75);

  const _DoneScreen({
    required this.exerciseName,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: _green,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                '¡Completado!',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exerciseName,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay),
                  label: Text(
                    'Repetir',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onExit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Salir',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
