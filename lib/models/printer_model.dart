import 'package:hive/hive.dart';

part 'printer_model.g.dart';

@HiveType(typeId: 3)
class Printer extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String location;

  @HiveField(3)
  final String model;

  @HiveField(4)
  final bool isDefault;

  @HiveField(5)
  final bool isAvailable;

  Printer({
    required this.name,
    required this.url,
    required this.location,
    required this.model,
    this.isDefault = false,
    this.isAvailable = true,
  });

  // 🔹 Clone method
  Printer copy() {
    return Printer(
      name: name,
      url: url,
      location: location,
      model: model,
      isDefault: isDefault,
      isAvailable: isAvailable,
    );
  }
}
