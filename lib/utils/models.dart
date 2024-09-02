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

@HiveType(typeId: 6)
class Ombrocoordinat extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int est;

  @HiveField(2)
  final int afd;

  @HiveField(3)
  final double lat;

  @HiveField(4)
  final double lon;

  @HiveField(5)
  final int status;

  @HiveField(6)
  final String images;

  Ombrocoordinat({
    required this.id,
    required this.est,
    required this.afd,
    required this.lat,
    required this.lon,
    required this.status,
    required this.images,
  });

  factory Ombrocoordinat.fromJson(Map<String, dynamic> json) {
    return Ombrocoordinat(
      id: json['id'] as int,
      est: json['est'] as int,
      afd: json['afd'] as int,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      status: json['status'] as int,
      images: json['images'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'est': est,
      'afd': afd,
      'lat': lat,
      'lon': lon,
      'status': status,
      'images': images,
    };
  }

  @override
  String toString() {
    return 'ID: $id, EST: $est, AFD: $afd, Lat: $lat, Lon: $lon, Status: $status, Images: $images';
  }
}
