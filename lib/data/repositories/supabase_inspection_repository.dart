import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/inspection_repository.dart';
import '../../models/inspection.dart';
import '../datasources/local_cache_service.dart';

class SupabaseInspectionRepository implements InspectionRepository {
  final SupabaseClient _client;
  final LocalCacheService _localCache;

  SupabaseInspectionRepository({
    required SupabaseClient client,
    required LocalCacheService localCache,
  })  : _client = client,
        _localCache = localCache;

  String _getCacheKey(String assetId) => 'cached_inspections_$assetId';
  String _getSiteCacheKey(String siteId) => 'cached_site_inspections_$siteId';

  @override
  Stream<List<Inspection>> getInspectionsStream(String assetId) async* {
    final cacheKey = _getCacheKey(assetId);
    
    // 1. Yield local cache first
    final cachedData = await _localCache.getCachedListData(cacheKey);
    if (cachedData != null) {
      yield cachedData.map((map) => Inspection.fromMap(map, map['id'] ?? '')).toList();
    }

    // 2. Yield remote stream and update cache
    yield* _client
        .from('inspections')
        .stream(primaryKey: ['id'])
        .eq('asset_id', assetId)
        .order('date', ascending: false)
        .map((data) {
          _localCache.cacheListData(cacheKey, data);
          return data.map((map) => Inspection.fromMap(map, map['id'])).toList();
        });
  }

  @override
  Future<Inspection?> getLatestInspection(String assetId) async {
    try {
      final response = await _client
          .from('inspections')
          .select()
          .eq('asset_id', assetId)
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response == null) return null;
      return Inspection.fromMap(response, response['id']);
    } catch (e) {
      // Offline fallback: try to get the latest from cache
      final cachedData = await _localCache.getCachedListData(_getCacheKey(assetId));
      if (cachedData != null && cachedData.isNotEmpty) {
        // Since stream sorts descending, the first one is the latest
        return Inspection.fromMap(cachedData.first, cachedData.first['id']);
      }
      return null;
    }
  }

  @override
  Future<List<Inspection>> getAllInspectionsForSite(String siteId) async {
    final cacheKey = _getSiteCacheKey(siteId);
    try {
      final assetsResponse = await _client.from('assets').select('id').eq('site_id', siteId);
      final assetIds = (assetsResponse as List).map((a) => a['id'] as String).toList();
      
      if (assetIds.isEmpty) return [];

      final response = await _client
          .from('inspections')
          .select()
          .inFilter('asset_id', assetIds)
          .order('date', ascending: false);
          
      final data = response as List;
      final listToCache = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      await _localCache.cacheListData(cacheKey, listToCache);
      
      return data.map((map) => Inspection.fromMap(map as Map<String, dynamic>, map['id'])).toList();
    } catch (e) {
       final cachedData = await _localCache.getCachedListData(cacheKey);
       if (cachedData != null) {
          return cachedData.map((map) => Inspection.fromMap(map, map['id'])).toList();
       }
       return [];
    }
  }

  @override
  Future<void> saveInspection(Inspection inspection) async {
    await _client.from('inspections').upsert(inspection.toMap());
  }
}
