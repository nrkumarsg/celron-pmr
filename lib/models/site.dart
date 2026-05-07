class Site {
  final String id;
  final String companyId;
  final String name; // Site Name
  final String partnerName;
  final String address;
  final String hqAddress;

  Site({
    required this.id,
    required this.companyId,
    required this.name,
    required this.partnerName,
    required this.address,
    this.hqAddress = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'partner_name': partnerName,
      'address': address,
      'partner_hq_address': hqAddress,
    };
  }

  factory Site.fromMap(Map<String, dynamic> map) {
    return Site(
      id: map['id'] ?? '',
      companyId: map['company_id'] ?? map['companyId'] ?? '',
      name: map['name'] ?? '',
      partnerName: map['partner_name'] ?? map['customerName'] ?? '',
      address: map['address'] ?? '',
      hqAddress: map['partner_hq_address'] ?? '',
    );
  }
}
