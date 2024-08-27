import 'package:hive/hive.dart';

part 'history.g.dart';

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

  History(
      {required this.afd,
      required this.est,
      required this.ch,
      required this.afdId,
      required this.estId});
}
