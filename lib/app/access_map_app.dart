import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/map/presentation/main_shell.dart';
import 'package:access_map/features/map/domain/place_repository.dart';
import 'package:access_map/features/summaries/domain/community_summary.dart';
import 'package:access_map/features/onboarding/presentation/mode_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccessPathAiApp extends StatelessWidget {
  const AccessPathAiApp({
    super.key,
    this.placeRepository,
    this.communitySummaryService,
  });

  final PlaceRepository? placeRepository;
  final CommunitySummaryService? communitySummaryService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(
        placeRepository: placeRepository,
        communitySummaryService: communitySummaryService,
      )..loadPlaces(),
      child: MaterialApp(
        title: 'AccessPath AI',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: Consumer<AppState>(
          builder: (context, state, _) {
            if (!state.profile.onboardingComplete) {
              return const ModeSelectionScreen();
            }
            return const MainShell();
          },
        ),
      ),
    );
  }
}
