import '../../models/asset.dart';

abstract class AssetRepository {
  /// Stream of assets for a specific site. 
  /// Supports offline-first local cache fallback.
  Stream<List<Asset>> getAssetsStream(String siteId);

  /// Fetch assets for a specific site.
  Future<List<Asset>> getAssets(String siteId);

  /// Save or update an asset.
  Future<void> saveAsset(Asset asset);

  /// Delete an asset.
  Future<void> deleteAsset(String assetId);
}
