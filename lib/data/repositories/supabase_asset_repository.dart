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
    
    // 1. Yield local cache first
    final cachedData = await _localCache.getCachedListData(cacheKey);
    if (cachedData != null) {
      yield cachedData.map((map) => Asset.fromMap(map)).toList();
    }

    // 2. Yield remote stream and update cache
    yield* _client
        .from('assets')
        .stream(primaryKey: ['id'])
        .eq('site_id', siteId)
        .order('name')
        .map((data) {
          _localCache.cacheListData(cacheKey, data);
          return data.map((map) => Asset.fromMap(map)).toList();
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
      final listToCache = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      await _localCache.cacheListData(cacheKey, listToCache);
      
      return data.map((map) => Asset.fromMap(map as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Network error fetching assets, falling back to cache: $e');
      final cachedData = await _localCache.getCachedListData(cacheKey);
      if (cachedData != null) {
        return cachedData.map((map) => Asset.fromMap(map)).toList();
      }
      return [];
    }
  }

  @override
  Future<void> saveAsset(Asset asset) async {
    final map = asset.toMap();
    // Convert to snake_case for Supabase if needed by schema. 
    // Assuming schema is snake_case based on previous code.
    final supabaseMap = {
      'id': map['id'],
      'site_id': map['siteId'],
      'name': map['name'],
      'reference': map['reference'],
      'model': map['model'],
      'type': map['type'],
      'location': map['location'],
      'rpm': map['rpm'],
      'hz': map['hz'],
      'power_kw': map['power_kw'],
    };
    await _client.from('assets').upsert(supabaseMap);
  }

  @override
  Future<void> deleteAsset(String assetId) async {
    await _client.from('assets').delete().eq('id', assetId);
  }
}
