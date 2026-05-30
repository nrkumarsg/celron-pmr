class LocationMapper {
  /// Resolves the Location dynamically based on the S/N or System Reference
  static String getMappedLocation(String reference, String fallback) {
    final refUpper = reference.toUpperCase();
    if (refUpper.contains('P7014') || refUpper.contains('P7015')) {
      return 'Loc.L3 (PWS System)';
    }
    if (refUpper.contains('P7051') || refUpper.contains('P7651')) {
      return 'Loc.L1 (WWTP(Outdoor) System)';
    }
    return fallback;
  }
}
