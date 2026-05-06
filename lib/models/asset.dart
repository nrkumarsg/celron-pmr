class Asset {
  final String id;
  final String siteId;
  final String name; // e.g. Waste Water Transfer Pump-1
  final String reference; // e.g. PMP-1011-01
  final String model;
  final String type;
  final String location; // e.g. L3
  final double rpm;
  final double hz;
  final double powerKw;

  Asset({
    required this.id,
    required this.siteId,
    required this.name,
    required this.reference,
    required this.model,
    required this.type,
    required this.location,
    this.rpm = 0.0,
    this.hz = 0.0,
    this.powerKw = 0.0,
  });

  String get systemName => name;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'siteId': siteId,
      'name': name,
      'reference': reference,
      'model': model,
      'type': type,
      'location': location,
      'rpm': rpm,
      'hz': hz,
      'power_kw': powerKw,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] ?? '',
      siteId: map['siteId'] ?? '',
      name: map['name'] ?? '',
      reference: map['reference'] ?? '',
      model: map['model'] ?? '',
      type: map['type'] ?? '',
      location: map['location'] ?? '',
      rpm: (map['rpm'] ?? 0.0).toDouble(),
      hz: (map['hz'] ?? 0.0).toDouble(),
      powerKw: (map['power_kw'] ?? 0.0).toDouble(),
    );
  }
}
