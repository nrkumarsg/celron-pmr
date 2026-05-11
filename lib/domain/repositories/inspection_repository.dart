import '../../models/inspection.dart';

abstract class InspectionRepository {
  /// Stream of inspections for a specific asset.
  /// Supports offline-first local cache fallback.
  Stream<List<Inspection>> getInspectionsStream(String assetId);

  /// Fetch the latest inspection for an asset.
  Future<Inspection?> getLatestInspection(String assetId);

  /// Fetch all inspections for a specific site (used for bulk reporting).
  Future<List<Inspection>> getAllInspectionsForSite(String siteId);

  /// Fetch inspections linked to a specific maintenance visit.
  Stream<List<Inspection>> getInspectionsByVisit(String visitId);

  /// Fetch inspections linked to a specific maintenance visit (non-stream).
  Future<List<Inspection>> getInspectionsByVisitAsync(String visitId);

  /// Save or update an inspection report.
  Future<void> saveInspection(Inspection inspection);
}
