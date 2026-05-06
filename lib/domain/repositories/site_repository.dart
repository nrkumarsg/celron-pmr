import '../../models/site.dart';

abstract class SiteRepository {
  /// Stream of sites. In a robust setup, this streams from a local cache
  /// which is kept in sync with the remote backend.
  Stream<List<Site>> getSitesStream();

  /// Fetch sites once (could be from local or remote)
  Future<List<Site>> getSites();

  /// Save or update a site. Updates local cache and syncs to remote.
  Future<void> saveSite(Site site);

  /// Delete a site and cascade delete associated assets/inspections.
  Future<void> deleteSite(String siteId);

  /// Get partner suggestions for autocomplete.
  Future<List<String>> getPartnerSuggestions(String query);
}
