// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainingSessionAdapter extends TypeAdapter<TrainingSession> {
  @override
  final int typeId = 2;

  @override
  TrainingSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingSession(
      id: fields[0] as String,
      weekday: fields[1] as int,
      title: fields[2] as String,
      subtitle: fields[3] as String,
      exerciseIds: (fields[4] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, TrainingSession obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.weekday)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.subtitle)
      ..writeByte(4)
      ..write(obj.exerciseIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
