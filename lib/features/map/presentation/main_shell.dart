import 'package:access_map/app/app_state.dart';
import 'package:access_map/features/contributions/presentation/contributions_screen.dart';
import 'package:access_map/features/map/presentation/map_screen.dart';
import 'package:access_map/features/map/presentation/discover_screen.dart';
import 'package:access_map/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pages = const [
      MapScreen(),
      DiscoverScreen(),
      ContributionsScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: state.tabIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.tabIndex,
        onDestinationSelected: context.read<AppState>().changeTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined), label: 'Contribute'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
