import 'package:cloud_firestore/cloud_firestore.dart';

enum HealthStatus { normal, marginal, critical }

class Inspection {
  final String id;
  final String assetId;
  final DateTime date;
  final String cycle; // e.g. 2nd Quarter
  final double vibrationG;
  final double temperatureC;
  final String? vibrationImgUrl;
  final String? tempImgUrl;
  
  // Dynamic parameters
  final Map<String, String> motorParameters; // Description -> Reading/Remark
  final Map<String, String> pumpParameters;
  final Map<String, String> otherParameters;

  final HealthStatus overallStatus;

  Inspection({
    required this.id,
    required this.assetId,
    required this.date,
    required this.cycle,
    required this.vibrationG,
    required this.temperatureC,
    this.vibrationImgUrl,
    this.tempImgUrl,
    required this.motorParameters,
    required this.pumpParameters,
    required this.otherParameters,
    required this.overallStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assetId': assetId,
      'date': Timestamp.fromDate(date),
      'cycle': cycle,
      'vibrationG': vibrationG,
      'temperatureC': temperatureC,
      'vibrationImgUrl': vibrationImgUrl,
      'tempImgUrl': tempImgUrl,
      'motorParameters': motorParameters,
      'pumpParameters': pumpParameters,
      'otherParameters': otherParameters,
      'overallStatus': overallStatus.index,
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map) {
    return Inspection(
      id: map['id'] ?? '',
      assetId: map['assetId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      cycle: map['cycle'] ?? '',
      vibrationG: (map['vibrationG'] ?? 0.0).toDouble(),
      temperatureC: (map['temperatureC'] ?? 0.0).toDouble(),
      vibrationImgUrl: map['vibrationImgUrl'],
      tempImgUrl: map['tempImgUrl'],
      motorParameters: Map<String, String>.from(map['motorParameters'] ?? {}),
      pumpParameters: Map<String, String>.from(map['pumpParameters'] ?? {}),
      otherParameters: Map<String, String>.from(map['otherParameters'] ?? {}),
      overallStatus: HealthStatus.values[map['overallStatus'] ?? 0],
    );
  }
}
