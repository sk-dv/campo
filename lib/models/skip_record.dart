import 'package:hive/hive.dart';

// reasonIndex: 0=planeado, 1=nutricion_personal, 2=imprevisto, 3=energia_baja
class SkipRecord extends HiveObject {
  late String id;
  late DateTime date;
  late String sessionId;
  late int reasonIndex;

  SkipRecord({
    required this.id,
    required this.date,
    required this.sessionId,
    required this.reasonIndex,
  });

  static const reasons = [
    'Descanso planeado',
    'Nutrición personal',
    'Imprevisto / fuerza mayor',
    'Energía baja / desánimo',
  ];

  static const reasonIcons = ['😴', '❤️', '⚡', '🔋'];

  String get reasonLabel => reasons[reasonIndex.clamp(0, reasons.length - 1)];
}

class SkipRecordAdapter extends TypeAdapter<SkipRecord> {
  @override
  final int typeId = 5;

  @override
  SkipRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SkipRecord(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      sessionId: fields[2] as String,
      reasonIndex: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SkipRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.sessionId)
      ..writeByte(3)
      ..write(obj.reasonIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkipRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
