import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalCacheService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getLocalFile(String key) async {
    final path = await _localPath;
    return File('$path/$key.json');
  }

  /// Saves a list of maps to the local cache under the given key.
  Future<void> cacheListData(String key, List<Map<String, dynamic>> data) async {
    try {
      final file = await _getLocalFile(key);
      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error caching data for key $key: $e');
    }
  }

  /// Retrieves a list of maps from the local cache. Returns null if not found.
  Future<List<Map<String, dynamic>>?> getCachedListData(String key) async {
    try {
      final file = await _getLocalFile(key);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> decodedList = jsonDecode(jsonString);
        return decodedList.map((e) => e as Map<String, dynamic>).toList();
      }
      return null;
    } catch (e) {
      print('Error reading cached data for key $key: $e');
      return null;
    }
  }

  /// Clears the specific cache key.
  Future<void> clearCache(String key) async {
    try {
      final file = await _getLocalFile(key);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error clearing cache for key $key: $e');
    }
  }
}
