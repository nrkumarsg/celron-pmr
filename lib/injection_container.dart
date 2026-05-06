import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'domain/repositories/site_repository.dart';
import 'data/repositories/supabase_site_repository.dart';
import 'domain/repositories/asset_repository.dart';
import 'data/repositories/supabase_asset_repository.dart';
import 'domain/repositories/inspection_repository.dart';
import 'data/repositories/supabase_inspection_repository.dart';
import 'data/datasources/local_cache_service.dart';

final sl = GetIt.instance; // sl = Service Locator

Future<void> init() async {
  // --- External Dependencies ---
  sl.registerLazySingleton(() => Supabase.instance.client);

  // --- Core / Data Sources ---
  sl.registerLazySingleton(() => LocalCacheService());

  // --- Repositories ---
  sl.registerLazySingleton<SiteRepository>(
      () => SupabaseSiteRepository(
            client: sl(),
            localCache: sl(),
          ));
          
  sl.registerLazySingleton<AssetRepository>(
      () => SupabaseAssetRepository(
            client: sl(),
            localCache: sl(),
          ));
          
  sl.registerLazySingleton<InspectionRepository>(
      () => SupabaseInspectionRepository(
            client: sl(),
            localCache: sl(),
          ));

  // --- Use Cases / BLoCs / Providers ---
  // e.g. sl.registerFactory(() => SiteProvider(repository: sl()));
}
