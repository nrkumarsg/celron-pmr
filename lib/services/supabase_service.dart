import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/site.dart';
import '../models/asset.dart';
import '../models/inspection.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- Sites ---
  Stream<List<Site>> getSites() {
    return _client
        .from('sites')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((data) => data.map((map) => Site.fromMap(map)).toList());
  }

  Future<void> saveSite(Site site) async {
    await _client.from('sites').upsert(site.toMap());
  }

  Future<void> deleteSite(String siteId) async {
    await _client.from('sites').delete().eq('id', siteId);
  }

  // --- Assets ---
  Stream<List<Asset>> getAssets(String siteId) {
    return _client
        .from('assets')
        .stream(primaryKey: ['id'])
        .eq('site_id', siteId)
        .order('name')
        .map((data) => data.map((map) => Asset.fromMap(map)).toList());
  }

  Future<void> saveAsset(Asset asset) async {
    final map = asset.toMap();
    // Convert to snake_case for Supabase
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
    };
    await _client.from('assets').upsert(supabaseMap);
  }

  Future<void> deleteAsset(String assetId) async {
    await _client.from('assets').delete().eq('id', assetId);
  }

  // --- Inspections ---
  Future<void> saveInspection(Inspection inspection) async {
    await _client.from('inspections').upsert(inspection.toMap());
  }

  Stream<List<Inspection>> getInspections(String assetId) {
    return _client
        .from('inspections')
        .stream(primaryKey: ['id'])
        .eq('asset_id', assetId)
        .order('date', ascending: false)
        .map((data) => data.map((map) => Inspection.fromMap(map, map['id'])).toList());
  }

  Future<Inspection?> getLatestInspection(String assetId) async {
    final response = await _client
        .from('inspections')
        .select()
        .eq('asset_id', assetId)
        .order('date', ascending: false)
        .limit(1)
        .maybeSingle();
    
    if (response == null) return null;
    return Inspection.fromMap(response, response['id']);
  }

  Future<List<Inspection>> getAllInspectionsForSite(String siteId) async {
    // Get all assets for this site first
    final assetsResponse = await _client.from('assets').select('id').eq('site_id', siteId);
    final assetIds = (assetsResponse as List).map((a) => a['id'] as String).toList();
    
    if (assetIds.isEmpty) return [];

    final response = await _client
        .from('inspections')
        .select()
        .inFilter('asset_id', assetIds)
        .order('date', ascending: false);
    
    return (response as List).map((map) => Inspection.fromMap(map, map['id'])).toList();
  }

  Future<List<String>> getPartnerSuggestions(String query) async {
    try {
      // Corrected based on database investigation: 
      // Table: 'partners', Column: 'name', Filter Column: 'types' (text array)
      final response = await _client
          .from('partners')
          .select('name')
          .contains('types', ['Customer'])
          .ilike('name', '%$query%')
          .limit(10);
      
      return (response as List).map((e) => e['name'] as String).toList();
    } catch (e) {
      try {
        // Fallback: Get unique partner names from existing sites
        final response = await _client
            .from('sites')
            .select('partner_name')
            .ilike('partner_name', '%$query%')
            .limit(20);
        
        final names = (response as List).map((e) => e['partner_name'] as String).toSet().toList();
        return names;
      } catch (innerError) {
        return [];
      }
    }
  }
}
