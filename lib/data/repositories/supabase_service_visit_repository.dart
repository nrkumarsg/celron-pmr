import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/service_visit_repository.dart';
import '../../models/service_visit.dart';
import '../datasources/local_cache_service.dart';

class SupabaseServiceVisitRepository implements ServiceVisitRepository {
  final SupabaseClient _client;
  final LocalCacheService _localCache;

  SupabaseServiceVisitRepository({
    required SupabaseClient client,
    required LocalCacheService localCache,
  })  : _client = client,
        _localCache = localCache;

  String _getCacheKey(String siteId) => 'cached_visits_$siteId';

  @override
  Stream<List<ServiceVisit>> getVisitsStream(String siteId) async* {
    final cacheKey = _getCacheKey(siteId);
    
    try {
      // 1. Local Cache
      final cachedData = await _localCache.getCachedListData(cacheKey);
      if (cachedData != null) {
        yield cachedData
            .where((e) => e != null)
            .map((map) => ServiceVisit.fromMap(Map<String, dynamic>.from(map)))
            .toList();
      }
    } catch (e) {
      print('SupabaseServiceVisitRepository: Error loading cache: $e');
    }

    // 2. Remote Stream
    yield* _client
        .from('service_visits')
        .stream(primaryKey: ['id'])
        .eq('site_id', siteId)
        .order('visit_date', ascending: false)
        .map((data) {
          try {
            // Client-side filtering as a safeguard for site isolation
            final filtered = data
                .where((e) => e != null && (e['site_id']?.toString() == siteId || e['siteId']?.toString() == siteId))
                .toList();

            _localCache.cacheListData(cacheKey, filtered);
            return filtered
                .map((map) => ServiceVisit.fromMap(Map<String, dynamic>.from(map)))
                .toList();
          } catch (e) {
            print('SupabaseServiceVisitRepository: Error mapping stream data: $e');
            return [];
          }
        });
  }

  @override
  Future<List<ServiceVisit>> getVisits(String siteId) async {
    final cacheKey = _getCacheKey(siteId);
    try {
      final response = await _client
          .from('service_visits')
          .select()
          .eq('site_id', siteId)
          .order('visit_date', ascending: false);
          
      final data = response as List;
      final listToCache = data
          .where((e) => e != null)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      await _localCache.cacheListData(cacheKey, listToCache);
      
      return listToCache.map((map) => ServiceVisit.fromMap(map)).toList();
    } catch (e) {
      print('Network error fetching visits, falling back to cache: $e');
      final cachedData = await _localCache.getCachedListData(cacheKey);
      if (cachedData != null) {
        return cachedData
            .where((e) => e != null)
            .map((map) => ServiceVisit.fromMap(Map<String, dynamic>.from(map)))
            .toList();
      }
      return [];
    }
  }

  @override
  Future<void> saveVisit(ServiceVisit visit) async {
    await _client.from('service_visits').upsert(visit.toMap());
  }

  @override
  Future<void> deleteVisit(String visitId) async {
    await _client.from('service_visits').delete().eq('id', visitId);
  }
}
