class Printers {
  final String name;
  final String url;
  final String location;
  final String model;
  final String comment;
  final bool isDefault;
  final bool isAvailable;

  Printers({
    required this.name,
    required this.url,
    required this.location,
    required this.model,
    this.comment = '',
    this.isDefault = false,
    this.isAvailable = true,
  });
}
