import 'package:access_map/app/access_map_app.dart';
import 'package:access_map/core/config/backend_config.dart';
import 'package:access_map/features/map/data/supabase_place_repository.dart';
import 'package:access_map/features/summaries/data/supabase_community_summary_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = BackendConfig.fromEnvironment();
  if (!config.isConfigured) {
    runApp(const AccessPathAiApp());
    return;
  }
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseAnonKey,
  );
  final client = Supabase.instance.client;
  if (client.auth.currentSession == null) {
    await client.auth.signInAnonymously();
  }
  runApp(
    AccessPathAiApp(
      placeRepository: SupabasePlaceRepository(client),
      communitySummaryService: SupabaseCommunitySummaryService(client),
    ),
  );
}
