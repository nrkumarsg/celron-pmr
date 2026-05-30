import 'dart:convert';

class ServiceVisit {
  final String id;
  final String siteId;
  final String celronRef;
  final String customerRef;
  final DateTime visitDate;
  final String notes;
  final String status;
  final String jobType; // AD_HOC or CONTRACT
  final DateTime? contractEnds;
  final DateTime createdAt;
  final String systemLocation; // Mentions system / location

  ServiceVisit({
    required this.id,
    required this.siteId,
    required this.celronRef,
    required this.customerRef,
    required this.visitDate,
    required this.notes,
    this.status = 'OPEN',
    this.jobType = 'AD_HOC',
    this.contractEnds,
    required this.createdAt,
    this.systemLocation = '',
  });

  Map<String, dynamic> toMap() {
    // Embed systemLocation inside notes to bypass db schema migrations
    final embeddedNotes = jsonEncode({
      'system_location': systemLocation,
      'notes': notes,
    });

    return {
      'id': id,
      'site_id': siteId,
      'celron_ref': celronRef,
      'customer_ref': customerRef,
      'visit_date': visitDate.toIso8601String(),
      'notes': embeddedNotes,
      'status': status,
      'job_type': jobType,
      'contract_ends': contractEnds?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ServiceVisit.fromMap(Map<String, dynamic> map) {
    final rawNotes = map['notes'] ?? '';
    String parsedNotes = rawNotes;
    String parsedSystemLocation = '';

    try {
      final decoded = jsonDecode(rawNotes) as Map<String, dynamic>;
      parsedNotes = decoded['notes']?.toString() ?? '';
      parsedSystemLocation = decoded['system_location']?.toString() ?? '';
    } catch (_) {
      // Legacy visits with plain text notes
      parsedNotes = rawNotes;
      parsedSystemLocation = '';
    }

    return ServiceVisit(
      id: map['id'] ?? '',
      siteId: map['site_id'] ?? '',
      celronRef: map['celron_ref'] ?? '',
      customerRef: map['customer_ref'] ?? '',
      visitDate: DateTime.parse(map['visit_date'] ?? DateTime.now().toIso8601String()),
      notes: parsedNotes,
      status: map['status'] ?? 'OPEN',
      jobType: map['job_type'] ?? 'AD_HOC',
      contractEnds: map['contract_ends'] != null ? DateTime.parse(map['contract_ends']) : null,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      systemLocation: parsedSystemLocation,
    );
  }
}
