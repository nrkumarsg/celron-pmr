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
    
    try {
      // 1. Yield local cache first
      final cachedData = await _localCache.getCachedListData(cacheKey);
      if (cachedData != null) {
        yield cachedData
            .where((e) => e != null)
            .map((map) => Inspection.fromMap(Map<String, dynamic>.from(map), map['id'] ?? ''))
            .toList();
      }
    } catch (e) {
      print('SupabaseInspectionRepository: Error loading cache: $e');
    }

    // 2. Yield remote stream and update cache
    yield* _client
        .from('inspections')
        .stream(primaryKey: ['id'])
        .eq('asset_id', assetId)
        .order('date', ascending: false)
        .map((data) {
          try {
            // Client-side filtering as a safeguard for asset isolation
            final filtered = data
                .where((e) => e != null && (e['asset_id']?.toString() == assetId || e['assetId']?.toString() == assetId))
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();

            _localCache.cacheListData(cacheKey, filtered);
            return filtered
                .map((map) => Inspection.fromMap(map, map['id'] ?? ''))
                .toList();
          } catch (e) {
            print('SupabaseInspectionRepository: Error mapping stream data: $e');
            return [];
          }
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
      return Inspection.fromMap(response, response['id'] ?? '');
    } catch (e) {
      // Offline fallback: try to get the latest from cache
      final cachedData = await _localCache.getCachedListData(_getCacheKey(assetId));
      if (cachedData != null && cachedData.isNotEmpty) {
        final first = cachedData.first;
        return Inspection.fromMap(Map<String, dynamic>.from(first), first['id'] ?? '');
      }
      return null;
    }
  }

  @override
  Future<List<Inspection>> getAllInspectionsForSite(String siteId) async {
    final cacheKey = _getSiteCacheKey(siteId);
    try {
      final assetsResponse = await _client.from('assets').select('id').eq('site_id', siteId);
      final assetIds = (assetsResponse as List)
          .where((e) => e != null)
          .map((a) => a['id'] as String)
          .toList();
      
      if (assetIds.isEmpty) return [];

      final response = await _client
          .from('inspections')
          .select()
          .inFilter('asset_id', assetIds)
          .order('date', ascending: false);
          
      final data = response as List;
      final listToCache = data
          .where((e) => e != null)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      await _localCache.cacheListData(cacheKey, listToCache);
      
      return listToCache
          .map((map) => Inspection.fromMap(map, map['id'] ?? ''))
          .toList();
    } catch (e) {
       final cachedData = await _localCache.getCachedListData(cacheKey);
       if (cachedData != null) {
          return cachedData
              .where((e) => e != null)
              .map((map) => Inspection.fromMap(Map<String, dynamic>.from(map), map['id'] ?? ''))
              .toList();
       }
       return [];
    }
  }

  @override
  Stream<List<Inspection>> getInspectionsByVisit(String visitId) async* {
    yield* _client
        .from('inspections')
        .stream(primaryKey: ['id'])
        .eq('visit_id', visitId)
        .order('date', ascending: false)
        .map((data) {
          // Client-side filtering as a safeguard for visit isolation
          return data
              .where((e) => e != null && (e['visit_id']?.toString() == visitId || e['visitId']?.toString() == visitId))
              .map((map) => Inspection.fromMap(Map<String, dynamic>.from(map), map['id']))
              .toList();
        });
  }

  @override
  Future<void> saveInspection(Inspection inspection) async {
    await _client.from('inspections').upsert(inspection.toMap());
  }
}
