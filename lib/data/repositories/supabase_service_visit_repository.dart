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
    
    // 1. Local Cache
    final cachedData = await _localCache.getCachedListData(cacheKey);
    if (cachedData != null) {
      yield cachedData.map((map) => ServiceVisit.fromMap(map)).toList();
    }

    // 2. Remote Stream
    yield* _client
        .from('service_visits')
        .stream(primaryKey: ['id'])
        .eq('site_id', siteId)
        .order('visit_date', ascending: false)
        .map((data) {
          _localCache.cacheListData(cacheKey, data);
          return data.map((map) => ServiceVisit.fromMap(map)).toList();
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
      final listToCache = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      await _localCache.cacheListData(cacheKey, listToCache);
      
      return data.map((map) => ServiceVisit.fromMap(map as Map<String, dynamic>)).toList();
    } catch (e) {
      final cachedData = await _localCache.getCachedListData(cacheKey);
      if (cachedData != null) {
        return cachedData.map((map) => ServiceVisit.fromMap(map)).toList();
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
