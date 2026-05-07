import 'package:flutter/material.dart';

enum HealthStatus { normal, marginal, critical }

class HealthLogic {
  static Map<String, String> getDualStatus(double g, double vMms, double kw) {
    String bearingStatus = getBearingStatus(g);
    String overallStatus = getVelocityStatus(vMms, kw);
    
    return {
      'bearing': bearingStatus,
      'overall': overallStatus,
      'summary': (bearingStatus == 'CRITICAL' || overallStatus == 'CRITICAL') ? 'CRITICAL' : 
                 (bearingStatus == 'MARGINAL' || overallStatus == 'MARGINAL') ? 'MARGINAL' : 'NORMAL'
    };
  }

  static String getBearingStatus(double g) {
    if (g < 0.2) return 'NORMAL';
    if (g < 0.5) return 'MARGINAL';
    return 'CRITICAL';
  }

  static String getVelocityStatus(double v, double kw) {
    // ISO 10816-3 simplified thresholds for typical industrial motors
    double limit1 = kw < 15 ? 0.71 : (kw < 75 ? 1.12 : 1.8); // Good
    double limit2 = kw < 15 ? 1.8 : (kw < 75 ? 2.8 : 4.5);   // Satisfactory
    double limit3 = kw < 15 ? 4.5 : (kw < 75 ? 7.1 : 11.2);  // Unsatisfactory

    if (v <= limit1) return 'NORMAL';
    if (v <= limit2) return 'NORMAL'; // Still acceptable
    if (v <= limit3) return 'MARGINAL';
    return 'CRITICAL';
  }

  static String getMaintenanceAdvice(double g, double v, double kw) {
    final status = getDualStatus(g, v, kw);
    String advice = '';

    if (status['bearing'] != 'NORMAL') {
      advice += 'BEARING: Check lubrication levels immediately. High acceleration suggests metal-to-metal contact. ';
    }
    if (status['overall'] != 'NORMAL') {
      advice += 'STRUCTURE: High velocity detected. Check for misalignment, base looseness, or imbalance. ';
    }
    
    if (advice.isEmpty) advice = 'Machine is operating within safe ISO limits. Continue quarterly monitoring.';
    return advice;
  }

  static HealthStatus getTemperatureStatus(double temp) {
    if (temp < 70) return HealthStatus.normal;
    if (temp <= 90) return HealthStatus.marginal;
    return HealthStatus.critical;
  }

  static String getStatusLabelFromEnum(HealthStatus status) {
    switch (status) {
      case HealthStatus.normal: return "NORMAL";
      case HealthStatus.marginal: return "MARGINAL";
      case HealthStatus.critical: return "CRITICAL";
    }
  }

  static Color getStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.normal:
        return Colors.green;
      case HealthStatus.marginal:
        return Colors.yellow;
      case HealthStatus.critical:
        return Colors.red;
    }
  }

  static String getStatusLabel(HealthStatus status) {
    switch (status) {
      case HealthStatus.normal:
        return "NORMAL";
      case HealthStatus.marginal:
        return "MARGINAL";
      case HealthStatus.critical:
        return "CRITICAL";
    }
  }

  static String getClass(double kw) {
    if (kw <= 0) return "Unknown";
    if (kw <= 15) return "Class I";
    if (kw <= 75) return "Class II";
    if (kw <= 300) return "Class III"; // Typical range for Class III (Rigid) or IV (Soft)
    return "Class IV"; // Or V/VI for larger
  }
}
