import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A cross-platform local cache service using SharedPreferences.
/// Works on Flutter Web, Android, iOS, and Desktop.
/// Replaces the previous dart:io File-based approach which crashed on Web.
class LocalCacheService {
  
  /// Saves a list of maps to the local cache under the given key.
  Future<void> cacheListData(String key, List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString(key, jsonString);
    } catch (e) {
      // Log but don't rethrow — cache failure should never crash the app
      print('LocalCacheService: Error caching data for key "$key": $e');
    }
  }

  /// Retrieves a list of maps from the local cache.
  /// Returns null if the key is not found or data is corrupted.
  Future<List<Map<String, dynamic>>?> getCachedListData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;

      final List<dynamic> decodedList = jsonDecode(jsonString);
      return decodedList
          .where((e) => e != null && e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      print('LocalCacheService: Error reading cached data for key "$key": $e');
      return null;
    }
  }

  /// Clears a specific cache key.
  Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      print('LocalCacheService: Error clearing cache for key "$key": $e');
    }
  }

  /// Clears all cached data managed by this service.
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('LocalCacheService: Error clearing all cache: $e');
    }
  }
}
