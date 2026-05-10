import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/site_repository.dart';
import '../../models/site.dart';
import '../datasources/local_cache_service.dart';

class SupabaseSiteRepository implements SiteRepository {
  final SupabaseClient _client;
  final LocalCacheService _localCache;
  static const String _sitesCacheKey = 'cached_sites';

  SupabaseSiteRepository({
    required SupabaseClient client,
    required LocalCacheService localCache,
  })  : _client = client,
        _localCache = localCache;

  @override
  Stream<List<Site>> getSitesStream() async* {
    print('SupabaseSiteRepository: Getting sites stream...');
    
    try {
      // 1. Yield local cache first for instant load
      final cachedData = await _localCache.getCachedListData(_sitesCacheKey);
      if (cachedData != null) {
        yield cachedData
            .where((e) => e != null)
            .map((map) => Site.fromMap(Map<String, dynamic>.from(map)))
            .toList();
      }
    } catch (e) {
      print('SupabaseSiteRepository: Error loading cache: $e');
    }

    // 2. Yield remote stream and update cache on each emission
    yield* _client
        .from('sites')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((data) {
          try {
            print('SupabaseSiteRepository: Stream received ${data.length} sites');
            // Update cache asynchronously
            _localCache.cacheListData(_sitesCacheKey, data);
            return data
                .where((e) => e != null)
                .map((map) => Site.fromMap(Map<String, dynamic>.from(map)))
                .toList();
          } catch (e) {
            print('SupabaseSiteRepository: Error mapping stream data: $e');
            return [];
          }
        });
  }

  @override
  Future<List<Site>> getSites() async {
    try {
      final response = await _client.from('sites').select().order('name');
      final data = response as List;
      // Convert elements to Map<String, dynamic> before caching
      final listToCache = data
          .where((e) => e != null)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      await _localCache.cacheListData(_sitesCacheKey, listToCache);
      return listToCache.map((map) => Site.fromMap(map)).toList();
    } catch (e) {
      print('Network error fetching sites, falling back to cache: $e');
      final cachedData = await _localCache.getCachedListData(_sitesCacheKey);
      if (cachedData != null) {
        return cachedData
            .where((e) => e != null)
            .map((map) => Site.fromMap(Map<String, dynamic>.from(map)))
            .toList();
      }
      return [];
    }
  }

  @override
  Future<void> saveSite(Site site) async {
    // Future improvement: Add to a local 'pending sync' queue if this fails
    await _client.from('sites').upsert(site.toMap());
  }

  @override
  Future<void> deleteSite(String siteId) async {
    await _client.from('sites').delete().eq('id', siteId);
  }

  @override
  Future<List<String>> getPartnerSuggestions(String query) async {
    try {
      final response = await _client
          .from('partners')
          .select('name')
          .contains('types', ['Customer'])
          .ilike('name', '%$query%')
          .limit(10);
      
      return (response as List).map((e) => e['name'] as String).toList();
    } catch (e) {
      try {
        final response = await _client
            .from('sites')
            .select('partner_name')
            .ilike('partner_name', '%$query%')
            .limit(20);
        
        final names = (response as List)
            .map((e) => e['partner_name'] as String)
            .toSet()
            .toList();
        return names;
      } catch (innerError) {
        return [];
      }
    }
  }
}

