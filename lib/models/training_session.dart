import 'package:hive/hive.dart';

part 'training_session.g.dart';

@HiveType(typeId: 2)
class TrainingSession extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late int weekday; // 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri

  @HiveField(2)
  late String title;

  @HiveField(3)
  late String subtitle; // location + duration

  @HiveField(4)
  late List<String> exerciseIds;

  TrainingSession({
    required this.id,
    required this.weekday,
    required this.title,
    required this.subtitle,
    required this.exerciseIds,
  });
}
