class Inspection {
  final String id;
  final String assetId;
  final DateTime date;
  final String projectRef;
  final String partnerRef;
  final String inspectionBy;
  final String quarterlyCycle; // e.g. Q1-24
  final double vibrationG;
  final double temperatureC;
  final String? vibrationImgUrl;
  final String? tempImgUrl;
  final Map<String, dynamic> motorParameters;
  final Map<String, dynamic> pumpParameters;
  final Map<String, dynamic> pipeParameters;
  final Map<String, dynamic> otherParameters;
  final String overallStatus;
  final String? visitId;

  Inspection({
    required this.id,
    required this.assetId,
    required this.date,
    required this.projectRef,
    required this.partnerRef,
    required this.inspectionBy,
    required this.quarterlyCycle,
    required this.vibrationG,
    required this.temperatureC,
    this.vibrationImgUrl,
    this.tempImgUrl,
    required this.motorParameters,
    required this.pumpParameters,
    required this.pipeParameters,
    required this.otherParameters,
    required this.overallStatus,
    this.visitId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'date': date.toIso8601String(),
      'project_ref': projectRef,
      'partner_ref': partnerRef,
      'inspection_by': inspectionBy,
      'quarterly_cycle': quarterlyCycle,
      'vibration_g': vibrationG,
      'temperature_c': temperatureC,
      'vibration_img_url': vibrationImgUrl,
      'temp_img_url': tempImgUrl,
      'motor_parameters': motorParameters,
      'pump_parameters': pumpParameters,
      'pipe_parameters': pipeParameters,
      'other_parameters': otherParameters,
      'overall_status': overallStatus,
      'visit_id': visitId,
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map, String id) {
    return Inspection(
      id: id,
      assetId: map['asset_id'] ?? map['assetId'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date'].toString()) : DateTime.now(),
      projectRef: map['project_ref'] ?? map['projectRef'] ?? '',
      partnerRef: map['partner_ref'] ?? map['partnerRef'] ?? map['customerRef'] ?? '',
      inspectionBy: map['inspection_by'] ?? map['inspectionBy'] ?? '',
      quarterlyCycle: map['quarterly_cycle'] ?? map['quarterlyCycle'] ?? '',
      vibrationG: (map['vibration_g'] ?? map['vibrationG'] ?? 0.0).toDouble(),
      temperatureC: (map['temperature_c'] ?? map['temperatureC'] ?? 0.0).toDouble(),
      vibrationImgUrl: map['vibration_img_url'] ?? map['vibrationImgUrl'],
      tempImgUrl: map['temp_img_url'] ?? map['tempImgUrl'],
      motorParameters: Map<String, dynamic>.from(map['motor_parameters'] ?? map['motorParameters'] ?? {}),
      pumpParameters: Map<String, dynamic>.from(map['pump_parameters'] ?? map['pumpParameters'] ?? {}),
      pipeParameters: Map<String, dynamic>.from(map['pipe_parameters'] ?? map['pipeParameters'] ?? {}),
      otherParameters: Map<String, dynamic>.from(map['other_parameters'] ?? map['otherParameters'] ?? {}),
      overallStatus: map['overall_status'] ?? map['overallStatus'] ?? 'NORMAL',
      visitId: map['visit_id'] ?? map['visitId'],
    );
  }
}
