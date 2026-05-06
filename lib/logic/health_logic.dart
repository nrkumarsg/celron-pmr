import 'package:flutter/material.dart';

enum HealthStatus { normal, marginal, critical }

class HealthLogic {
  static HealthStatus getVibrationStatus(double g) {
    if (g < 0.1) return HealthStatus.normal;
    if (g <= 0.4) return HealthStatus.marginal;
    return HealthStatus.critical;
  }

  static HealthStatus getTemperatureStatus(double temp) {
    if (temp < 70) return HealthStatus.normal;
    if (temp <= 90) return HealthStatus.marginal;
    return HealthStatus.critical;
  }

  static HealthStatus getOverallStatus(double g, double temp) {
    final vStatus = getVibrationStatus(g);
    final tStatus = getTemperatureStatus(temp);

    if (vStatus == HealthStatus.critical || tStatus == HealthStatus.critical) {
      return HealthStatus.critical;
    }
    if (vStatus == HealthStatus.marginal || tStatus == HealthStatus.marginal) {
      return HealthStatus.marginal;
    }
    return HealthStatus.normal;
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
