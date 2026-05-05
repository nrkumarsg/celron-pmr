import 'package:cloud_firestore/cloud_firestore.dart';

class Inspection {
  final String id;
  final String assetId;
  final DateTime date;
  final String projectRef;
  final String customerRef;
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

  Inspection({
    required this.id,
    required this.assetId,
    required this.date,
    required this.projectRef,
    required this.customerRef,
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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assetId': assetId,
      'date': Timestamp.fromDate(date),
      'projectRef': projectRef,
      'customerRef': customerRef,
      'inspectionBy': inspectionBy,
      'quarterlyCycle': quarterlyCycle,
      'vibrationG': vibrationG,
      'temperatureC': temperatureC,
      'vibrationImgUrl': vibrationImgUrl,
      'tempImgUrl': tempImgUrl,
      'motorParameters': motorParameters,
      'pumpParameters': pumpParameters,
      'pipeParameters': pipeParameters,
      'otherParameters': otherParameters,
      'overallStatus': overallStatus,
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map, String id) {
    return Inspection(
      id: id,
      assetId: map['assetId'],
      date: (map['date'] as Timestamp).toDate(),
      projectRef: map['projectRef'] ?? '',
      customerRef: map['customerRef'] ?? '',
      inspectionBy: map['inspectionBy'] ?? '',
      quarterlyCycle: map['quarterlyCycle'] ?? '',
      vibrationG: (map['vibrationG'] as num).toDouble(),
      temperatureC: (map['temperatureC'] as num).toDouble(),
      vibrationImgUrl: map['vibrationImgUrl'],
      tempImgUrl: map['tempImgUrl'],
      motorParameters: Map<String, dynamic>.from(map['motorParameters'] ?? {}),
      pumpParameters: Map<String, dynamic>.from(map['pumpParameters'] ?? {}),
      pipeParameters: Map<String, dynamic>.from(map['pipeParameters'] ?? {}),
      otherParameters: Map<String, dynamic>.from(map['otherParameters'] ?? {}),
      overallStatus: map['overallStatus'],
    );
  }
}
