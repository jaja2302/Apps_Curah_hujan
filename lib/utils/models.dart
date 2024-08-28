import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
class History extends HiveObject {
  @HiveField(0)
  String afd;

  @HiveField(1)
  String est;

  @HiveField(2)
  String ch;

  @HiveField(3)
  String afdId;

  @HiveField(4)
  String estId;

  History({
    required this.afd,
    required this.est,
    required this.ch,
    required this.afdId,
    required this.estId,
  });
}

@HiveType(typeId: 5)
class EstatePlot extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String est;

  @HiveField(2)
  final double lat;

  @HiveField(3)
  final double lon;

  EstatePlot({
    required this.id,
    required this.est,
    required this.lat,
    required this.lon,
  });

  @override
  String toString() {
    return 'ID: $id, EST: $est, Lat: $lat, Lon: $lon';
  }
}
