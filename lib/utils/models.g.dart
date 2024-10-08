// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryAdapter extends TypeAdapter<History> {
  @override
  final int typeId = 0;

  @override
  History read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return History(
      afd: fields[0] as String,
      est: fields[1] as String,
      ch: fields[2] as String,
      afdId: fields[3] as String,
      estId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, History obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.afd)
      ..writeByte(1)
      ..write(obj.est)
      ..writeByte(2)
      ..write(obj.ch)
      ..writeByte(3)
      ..write(obj.afdId)
      ..writeByte(4)
      ..write(obj.estId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EstatePlotAdapter extends TypeAdapter<EstatePlot> {
  @override
  final int typeId = 5;

  @override
  EstatePlot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EstatePlot(
      id: fields[0] as int,
      est: fields[1] as String,
      lat: fields[2] as double,
      lon: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, EstatePlot obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.est)
      ..writeByte(2)
      ..write(obj.lat)
      ..writeByte(3)
      ..write(obj.lon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstatePlotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OmbrocoordinatAdapter extends TypeAdapter<Ombrocoordinat> {
  @override
  final int typeId = 6;

  @override
  Ombrocoordinat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Ombrocoordinat(
      id: fields[0] as int,
      est: fields[1] as int,
      afd: fields[2] as int,
      lat: fields[3] as double,
      lon: fields[4] as double,
      status: fields[5] as int,
      images: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Ombrocoordinat obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.est)
      ..writeByte(2)
      ..write(obj.afd)
      ..writeByte(3)
      ..write(obj.lat)
      ..writeByte(4)
      ..write(obj.lon)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.images);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OmbrocoordinatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AfdelingAdapter extends TypeAdapter<Afdeling> {
  @override
  final int typeId = 6;

  @override
  Afdeling read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Afdeling(
      id: fields[0] as int,
      nama: fields[1] as String,
      estate: fields[2] as int,
      ombro_lon: fields[3] as double?,
      ombro_lat: fields[4] as double?,
      ombro_status: fields[5] as String,
      ombro_images: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Afdeling obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nama)
      ..writeByte(2)
      ..write(obj.estate)
      ..writeByte(3)
      ..write(obj.ombro_lon)
      ..writeByte(4)
      ..write(obj.ombro_lat)
      ..writeByte(5)
      ..write(obj.ombro_status)
      ..writeByte(6)
      ..write(obj.ombro_images);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AfdelingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
