import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'hive_service.dart';
import '../models/exercise.dart';

class BackupService {
  static const _version = 1;
  static const _fileName = 'campo_backup.zip';

  // ── Export ─────────────────────────────────────────────────────────────────

  static Future<void> exportBackup() async {
    final tempDir = await getTemporaryDirectory();
    final zipPath = p.join(tempDir.path, _fileName);

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    // Serialize exercises to JSON
    final exercises = HiveService.exercises.values.toList();
    final jsonList = exercises.map(_exerciseToJson).toList();
    final jsonBytes = utf8.encode(jsonEncode({
      'version': _version,
      'exportDate': DateTime.now().toIso8601String(),
      'exercises': jsonList,
    }));
    encoder.addArchiveFile(
      ArchiveFile('data.json', jsonBytes.length, jsonBytes),
    );

    // Add image files
    for (final exercise in exercises) {
      for (final imgPath in exercise.imagePaths) {
        final file = File(imgPath);
        if (await file.exists()) {
          final fileName = p.basename(imgPath);
          encoder.addFile(file, 'images/$fileName');
        }
      }
    }

    encoder.closeSync();

    await Share.shareXFiles(
      [XFile(zipPath)],
      subject: 'Campo — Backup',
    );
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  static Future<String> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return 'cancelled';
    }

    final zipPath = result.files.first.path;
    if (zipPath == null) return 'error';

    final appDir = await getApplicationDocumentsDirectory();
    final imgDir = p.join(appDir.path, 'exercise_images');
    await Directory(imgDir).create(recursive: true);

    // Extract ZIP
    final inputStream = InputFileStream(zipPath);
    final archive = ZipDecoder().decodeBuffer(inputStream);

    Map<String, dynamic>? jsonData;
    final imageFiles = <String, List<int>>{};

    for (final file in archive) {
      if (file.isFile) {
        final content = file.content as List<int>;
        if (file.name == 'data.json') {
          jsonData = jsonDecode(utf8.decode(content)) as Map<String, dynamic>;
        } else if (file.name.startsWith('images/')) {
          final name = p.basename(file.name);
          imageFiles[name] = content;
        }
      }
    }
    inputStream.closeSync();

    if (jsonData == null) return 'invalid';

    // Write image files to disk
    for (final entry in imageFiles.entries) {
      final destPath = p.join(imgDir, entry.key);
      await File(destPath).writeAsBytes(entry.value);
    }

    // Restore exercises
    final rawExercises = jsonData['exercises'] as List<dynamic>;
    final restored = rawExercises
        .map((e) => _exerciseFromJson(e as Map<String, dynamic>, imgDir))
        .toList();

    // Clear and replace all exercises
    await HiveService.exercises.clear();
    for (final exercise in restored) {
      await HiveService.exercises.put(exercise.id, exercise);
    }

    return 'ok';
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  static Map<String, dynamic> _exerciseToJson(Exercise e) {
    return {
      'id': e.id,
      'name': e.name,
      'category': e.category.name,
      'durationMinutes': e.durationMinutes,
      'instructions': e.instructions,
      'imageFileNames': e.imagePaths.map(p.basename).toList(),
      'imageTimerSeconds': e.imageTimerSeconds,
      'defaultTimerSeconds': e.defaultTimerSeconds,
    };
  }

  static Exercise _exerciseFromJson(
      Map<String, dynamic> json, String imgDir) {
    final category = ExerciseCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => ExerciseCategory.movilidad,
    );

    final fileNames = (json['imageFileNames'] as List<dynamic>? ?? [])
        .cast<String>();
    final imagePaths = fileNames.map((f) => p.join(imgDir, f)).toList();

    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: category,
      durationMinutes: json['durationMinutes'] as int,
      instructions: (json['instructions'] as List<dynamic>).cast<String>(),
      imagePaths: imagePaths,
      imageTimerSeconds:
          (json['imageTimerSeconds'] as List<dynamic>? ?? []).cast<int>(),
      defaultTimerSeconds: json['defaultTimerSeconds'] as int? ?? 0,
    );
  }
}
