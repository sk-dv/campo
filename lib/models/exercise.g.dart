// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 1;

  @override
  Exercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exercise(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as ExerciseCategory,
      durationMinutes: fields[3] as int,
      instructions: (fields[4] as List).cast<String>(),
      imagePaths: (fields[5] as List).cast<String>(),
      imageTimerSeconds: (fields[6] as List?)?.cast<int>() ?? [],
      defaultTimerSeconds: fields[7] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.instructions)
      ..writeByte(5)
      ..write(obj.imagePaths)
      ..writeByte(6)
      ..write(obj.imageTimerSeconds)
      ..writeByte(7)
      ..write(obj.defaultTimerSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseCategoryAdapter extends TypeAdapter<ExerciseCategory> {
  @override
  final int typeId = 0;

  @override
  ExerciseCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExerciseCategory.tecnica;
      case 1:
        return ExerciseCategory.fisico;
      case 2:
        return ExerciseCategory.movilidad;
      case 3:
        return ExerciseCategory.mental;
      default:
        return ExerciseCategory.tecnica;
    }
  }

  @override
  void write(BinaryWriter writer, ExerciseCategory obj) {
    switch (obj) {
      case ExerciseCategory.tecnica:
        writer.writeByte(0);
        break;
      case ExerciseCategory.fisico:
        writer.writeByte(1);
        break;
      case ExerciseCategory.movilidad:
        writer.writeByte(2);
        break;
      case ExerciseCategory.mental:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
