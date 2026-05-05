class Asset {
  final String id;
  final String siteId;
  final String name; // e.g. Waste Water Transfer Pump-1
  final String reference; // e.g. PMP-1011-01
  final String model;
  final String type;

  Asset({
    required this.id,
    required this.siteId,
    required this.name,
    required this.reference,
    required this.model,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'siteId': siteId,
      'name': name,
      'reference': reference,
      'model': model,
      'type': type,
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
    );
  }
}
