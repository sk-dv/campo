import 'package:cloud_functions/cloud_functions.dart';
import 'hive_service.dart';

class CoachService {
  static Future<String> askCoach({
    int? energyLevel,
    double? sleepHours,
    String? note,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'askCoach',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );

    final Map<String, dynamic> context = {
      'cycleName': HiveService.cycleName ?? 'Ciclo activo',
      'daysLeft': HiveService.daysUntilCycleEnd(),
      'sessionsThisWeek': HiveService.sessionsCompletedThisWeek(),
      'targetThisWeek': HiveService.currentWeekTarget(),
    };

    if (energyLevel != null) {
      context['checkin'] = {
        'energyLevel': energyLevel,
        'sleepHours': sleepHours ?? 0.0,
        'note': note ?? '',
      };
    }

    final result = await callable.call({'context': context});
    return result.data['text'] as String;
  }
}
