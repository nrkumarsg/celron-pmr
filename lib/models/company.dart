class Company {
  final String id;
  final String name;
  final String regOffice;
  final String phone;
  final String fax;
  final String mobile;
  final String email;
  final String web;
  final String brn;
  final String gstReg;

  const Company({
    required this.id,
    required this.name,
    required this.regOffice,
    required this.phone,
    required this.fax,
    required this.mobile,
    required this.email,
    required this.web,
    required this.brn,
    required this.gstReg,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'regOffice': regOffice,
      'phone': phone,
      'fax': fax,
      'mobile': mobile,
      'email': email,
      'web': web,
      'brn': brn,
      'gstReg': gstReg,
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      regOffice: map['regOffice'] ?? '',
      phone: map['phone'] ?? '',
      fax: map['fax'] ?? '',
      mobile: map['mobile'] ?? '',
      email: map['email'] ?? '',
      web: map['web'] ?? '',
      brn: map['brn'] ?? '',
      gstReg: map['gstReg'] ?? '',
    );
  }
}
