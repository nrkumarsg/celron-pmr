class Site {
  final String id;
  final String companyId;
  final String name;
  final String address;

  Site({
    required this.id,
    required this.companyId,
    required this.name,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'address': address,
    };
  }

  factory Site.fromMap(Map<String, dynamic> map) {
    return Site(
      id: map['id'] ?? '',
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
    );
  }
}
