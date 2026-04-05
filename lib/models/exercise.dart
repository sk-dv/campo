import 'package:hive/hive.dart';

part 'exercise.g.dart';

@HiveType(typeId: 0)
enum ExerciseCategory {
  @HiveField(0)
  tecnica,
  @HiveField(1)
  fisico,
  @HiveField(2)
  movilidad,
  @HiveField(3)
  mental,
}

@HiveType(typeId: 1)
class Exercise extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late ExerciseCategory category;

  @HiveField(3)
  late int durationMinutes;

  @HiveField(4)
  late List<String> instructions;

  @HiveField(5)
  late List<String> imagePaths;

  @HiveField(6)
  late List<int> imageTimerSeconds;

  @HiveField(7)
  late int defaultTimerSeconds;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMinutes,
    required this.instructions,
    List<String>? imagePaths,
    List<int>? imageTimerSeconds,
    int? defaultTimerSeconds,
  })  : imagePaths = imagePaths ?? [],
        imageTimerSeconds = imageTimerSeconds ?? [],
        defaultTimerSeconds = defaultTimerSeconds ?? 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category.name,
        'durationMinutes': durationMinutes,
        'instructions': instructions,
        'imagePaths': imagePaths,
        'imageTimerSeconds': imageTimerSeconds,
        'defaultTimerSeconds': defaultTimerSeconds,
      };
}
