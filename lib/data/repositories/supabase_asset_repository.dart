import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/asset_repository.dart';
import '../../models/asset.dart';
import '../datasources/local_cache_service.dart';

class SupabaseAssetRepository implements AssetRepository {
  final SupabaseClient _client;
  final LocalCacheService _localCache;

  SupabaseAssetRepository({
    required SupabaseClient client,
    required LocalCacheService localCache,
  })  : _client = client,
        _localCache = localCache;

  String _getCacheKey(String siteId) => 'cached_assets_$siteId';

  @override
  Stream<List<Asset>> getAssetsStream(String siteId) async* {
    final cacheKey = _getCacheKey(siteId);
    
    try {
      // 1. Yield local cache first
      final cachedData = await _localCache.getCachedListData(cacheKey);
      if (cachedData != null) {
        yield cachedData
            .where((e) => e != null)
            .map((map) => Asset.fromMap(Map<String, dynamic>.from(map)))
            .toList();
      }
    } catch (e) {
      print('SupabaseAssetRepository: Error loading cache: $e');
    }

    // 2. Yield remote stream and update cache
    yield* _client
        .from('assets')
        .stream(primaryKey: ['id'])
        .eq('site_id', siteId)
        .order('name')
        .map((data) {
          try {
            // Client-side filtering as a safeguard for site isolation
            final filtered = data
                .where((e) => e != null && (e['site_id']?.toString() == siteId || e['siteId']?.toString() == siteId))
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();

            _localCache.cacheListData(cacheKey, filtered);
            return filtered
                .map((map) => Asset.fromMap(map))
                .toList();
          } catch (e) {
            print('SupabaseAssetRepository: Error mapping stream data: $e');
            return [];
          }
        });
  }

  @override
  Future<List<Asset>> getAssets(String siteId) async {
    final cacheKey = _getCacheKey(siteId);
    try {
      final response = await _client
          .from('assets')
          .select()
          .eq('site_id', siteId)
          .order('name');
          
      final data = response as List;
      final listToCache = data
          .where((e) => e != null)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      await _localCache.cacheListData(cacheKey, listToCache);
      
      return listToCache.map((map) => Asset.fromMap(map)).toList();
    } catch (e) {
      print('Network error fetching assets, falling back to cache: $e');
      final cachedData = await _localCache.getCachedListData(cacheKey);
      if (cachedData != null) {
        return cachedData
            .where((e) => e != null)
            .map((map) => Asset.fromMap(Map<String, dynamic>.from(map)))
            .toList();
      }
      return [];
    }
  }

  @override
  Future<void> saveAsset(Asset asset) async {
    await _client.from('assets').upsert(asset.toMap());
  }

  @override
  Future<void> deleteAsset(String assetId) async {
    await _client.from('assets').delete().eq('id', assetId);
  }
}
