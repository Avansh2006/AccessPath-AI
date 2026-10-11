import 'dart:math' as math;

import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/services/geocoding_service.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/contribute/presentation/add_location_screen.dart';
import 'package:access_map/features/map/domain/live_map_explorer.dart';
import 'package:access_map/features/map/domain/place_repository.dart';
import 'package:access_map/features/map/presentation/live_map_widgets.dart';
import 'package:access_map/features/places/presentation/place_details_screen.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_category.dart';
import 'package:access_map/shared/models/accessibility_rating.dart';
import 'package:access_map/shared/widgets/access_search_bar.dart';
import 'package:access_map/shared/widgets/app_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

/// Live Accessibility Explorer: nearby venues coloured by personal fit.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _highlyFriendlyOnly = false;

  @override
  void initState() {
    super.initState();
    // Discover around the user's real location on first open; the map
    // falls back to the default area (with a banner) if this fails.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      if (state.locationStatus == null && !state.hasUserLocation) {
        state.locateUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final searching = state.searchQuery.isNotEmpty || state.isSearching;
    final searchResults = state.rankForRequirements(
      _applyFriendly(state.visiblePlaces),
    );
    final explorerPlaces = _applyFriendly(state.explorerPlaces);
    final selected = state.selectedPlace;
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: state.isLoadingPlaces
                ? const Center(child: CircularProgressIndicator())
                : _AccessibleMap(
                    key: ValueKey(
                      '${state.mapLatitude},${state.mapLongitude},'
                      '${state.explorerRadius.name}',
                    ),
                    places: explorerPlaces,
                    selectedPlace: selected,
                    center: LatLng(state.mapLatitude, state.mapLongitude),
                    radius: state.explorerRadius,
                    userLocation: state.hasUserLocation
                        ? LatLng(state.userLatitude!, state.userLongitude!)
                        : null,
                  ),
          ),
          Positioned(
            top: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AccessSearchBar(),
                if (searching)
                  _SearchResults(places: searchResults)
                else ...[
                  const SizedBox(height: AppSpacing.sm),
                  _ExplorerFilterBar(onOpenFilters: () => _showFilters(context)),
                  if (!state.isLoadingPlaces && state.errorMessage == null)
                    _ExplorerStatusBanner(places: explorerPlaces),
                ],
              ],
            ),
          ),
          if (state.errorMessage != null)
            EmptyState(
              title: "Couldn't load nearby places",
              message: 'Please check your connection and try again.',
              action: ElevatedButton(
                onPressed: context.read<AppState>().loadPlaces,
                child: const Text('Retry'),
              ),
            ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'add-location',
                  tooltip: 'Add a new location',
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddLocationScreen(),
                    ),
                  ),
                  child: const Icon(Icons.add_location_alt_outlined),
                ),
                const SizedBox(height: AppSpacing.md),
                FloatingActionButton.small(
                  heroTag: 'location',
                  tooltip: 'Use current location',
                  onPressed: state.isLocating
                      ? null
                      : () async {
                          final found = await context
                              .read<AppState>()
                              .useCurrentLocation();
                          if (!found && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Location is unavailable or permission was denied.',
                                ),
                              ),
                            );
                          }
                        },
                  child: Icon(
                    state.isLocating
                        ? Icons.location_searching
                        : Icons.my_location,
                  ),
                ),
                if (selected != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  VenueCard(
                    place: selected,
                    result: state.suitabilityFor(selected),
                    relevantCriteria: state.relevantCriteria,
                    userLatitude: state.userLatitude,
                    userLongitude: state.userLongitude,
                    onClose: context.read<AppState>().clearSelectedPlace,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Place> _applyFriendly(List<Place> places) => _highlyFriendlyOnly
      ? places.where((place) => place.friendlyScore >= 8.5).toList()
      : places;

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filters', style: AppTypography.headlineSmall),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Marker colours', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Colours reflect community ratings for the accessibility '
                    'needs in your profile. Places nobody has rated stay grey.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const SuitabilityLegend(),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _highlyFriendlyOnly,
                    onChanged: (value) {
                      setState(() => _highlyFriendlyOnly = value);
                      setModalState(() {});
                    },
                    title: const Text('Highly friendly'),
                    subtitle: const Text('Friendly Score 8.5 and above'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Essential accessibility requirements'),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: AccessibilityCriterion.values.map((criterion) {
                      final selected = context
                          .read<AppState>()
                          .essentialRequirements
                          .contains(criterion);
                      return FilterChip(
                        label: Text(criterion.label),
                        selected: selected,
                        onSelected: (_) {
                          context.read<AppState>().toggleEssentialRequirement(
                            criterion,
                          );
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: context.read<AppState>().verifiedEssentialsOnly,
                    onChanged: (value) {
                      context.read<AppState>().setVerifiedEssentialsOnly(value);
                      setModalState(() {});
                    },
                    title: const Text('Verified matches only'),
                    subtitle: const Text(
                      'Unknown information is excluded, never assumed accessible.',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Category chips, radius selector and live-update indicator.
class _ExplorerFilterBar extends StatelessWidget {
  const _ExplorerFilterBar({required this.onOpenFilters});

  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            key: const ValueKey('explorer-category-chips'),
            scrollDirection: Axis.horizontal,
            children: [
              IconButton.filledTonal(
                tooltip: 'Filters',
                visualDensity: VisualDensity.compact,
                onPressed: onOpenFilters,
                icon: const Icon(Icons.tune),
              ),
              const SizedBox(width: AppSpacing.xs),
              _CategoryChip(
                label: 'All',
                icon: Icons.apps,
                selected: state.explorerCategory == null,
                onSelected: () => state.setExplorerCategory(null),
              ),
              for (final category in ExplorerCategory.values)
                _CategoryChip(
                  label: category.label,
                  icon: _categoryIcon(category),
                  selected: state.explorerCategory == category,
                  onSelected: () => state.setExplorerCategory(category),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            SegmentedButton<ExplorerRadius>(
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStatePropertyAll(AppColors.surface),
              ),
              segments: [
                for (final radius in ExplorerRadius.values)
                  ButtonSegment(
                    value: radius,
                    label: Text(radius.label),
                    tooltip: 'Within ${radius.label}',
                  ),
              ],
              selected: {state.explorerRadius},
              onSelectionChanged: (selection) =>
                  state.setExplorerRadius(selection.first),
            ),
            const Spacer(),
            _LiveIndicator(status: state.liveUpdatesStatus),
          ],
        ),
      ],
    );
  }

  static IconData _categoryIcon(ExplorerCategory category) =>
      switch (category) {
        ExplorerCategory.hospitals => PlaceCategory.hospital.icon,
        ExplorerCategory.restaurants => PlaceCategory.restaurant.icon,
        ExplorerCategory.malls => PlaceCategory.mall.icon,
        ExplorerCategory.parks => PlaceCategory.park.icon,
        ExplorerCategory.transport => PlaceCategory.transport.icon,
        ExplorerCategory.other => Icons.place_outlined,
      };
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        backgroundColor: AppColors.surface,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator({required this.status});

  final LiveUpdatesStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      // No realtime backend (e.g. offline demo data): claim nothing.
      LiveUpdatesStatus.unsupported => (null, AppColors.textTertiary),
      LiveUpdatesStatus.connecting => ('Connecting…', AppColors.textSecondary),
      LiveUpdatesStatus.live => ('Live updates', AppColors.success),
      LiveUpdatesStatus.error => ('Live updates off', AppColors.error),
    };
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderRadiusFull,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTypography.labelMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// One contextual notice at a time, most important first: location
/// problems, stale data, no results, then missing accessibility data.
class _ExplorerStatusBanner extends StatelessWidget {
  const _ExplorerStatusBanner({required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final banner = _bannerFor(context, state);
    if (banner == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: banner,
    );
  }

  Widget? _bannerFor(BuildContext context, AppState state) {
    final status = state.locationStatus;
    if (!state.hasUserLocation &&
        status != null &&
        status != LocationLookupStatus.found) {
      final (message, actionLabel) = switch (status) {
        LocationLookupStatus.denied => (
          'Location permission is off. Showing the default area instead.',
          'Allow',
        ),
        LocationLookupStatus.deniedForever => (
          'Location permission is blocked. Enable it in Settings to see places near you.',
          'Settings',
        ),
        LocationLookupStatus.serviceDisabled => (
          'Location services are off. Showing the default area instead.',
          'Turn on',
        ),
        _ => (
          "Couldn't read your location. Showing the default area instead.",
          'Retry',
        ),
      };
      return _Notice(
        key: const ValueKey('location-banner'),
        icon: Icons.location_off_outlined,
        color: AppColors.warning,
        message: message,
        actionLabel: actionLabel,
        onAction: () {
          final appState = context.read<AppState>();
          if (status == LocationLookupStatus.deniedForever ||
              status == LocationLookupStatus.serviceDisabled) {
            appState.openLocationSettings();
          } else {
            appState.locateUser();
          }
        },
      );
    }
    if (state.liveRefreshFailed) {
      return _Notice(
        key: const ValueKey('refresh-banner'),
        icon: Icons.cloud_off_outlined,
        color: AppColors.error,
        message: "Couldn't refresh. Showing the last loaded data.",
        actionLabel: 'Retry',
        onAction: context.read<AppState>().refreshFromBackend,
      );
    }
    if (places.isEmpty) {
      final what = state.explorerCategory?.label.toLowerCase() ?? 'places';
      final canWiden = state.explorerRadius != ExplorerRadius.values.last;
      return _Notice(
        key: const ValueKey('empty-banner'),
        icon: Icons.search_off,
        color: AppColors.info,
        message: 'No $what found within ${state.explorerRadius.label}.',
        actionLabel: canWiden ? 'Widen to 5 km' : null,
        onAction: canWiden
            ? () => context.read<AppState>().setExplorerRadius(
                ExplorerRadius.values.last,
              )
            : null,
      );
    }
    final unrated = places
        .where(
          (place) =>
              state.suitabilityFor(place).suitability == Suitability.unknown,
        )
        .length;
    if (unrated == places.length) {
      return const _Notice(
        key: ValueKey('no-data-banner'),
        icon: Icons.info_outline,
        color: AppColors.info,
        message:
            'No community accessibility ratings here yet. Grey markers mean '
            'unknown, not inaccessible. Add a review to help others.',
      );
    }
    return null;
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 2,
      borderRadius: AppRadii.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message, style: AppTypography.bodySmall)),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

class _AccessibleMap extends StatelessWidget {
  const _AccessibleMap({
    super.key,
    required this.places,
    required this.selectedPlace,
    required this.center,
    required this.radius,
    required this.userLocation,
  });

  final List<Place> places;
  final Place? selectedPlace;
  final LatLng center;
  final ExplorerRadius radius;
  final LatLng? userLocation;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: radius.zoom),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.access_map',
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: radius.km * 1000,
              useRadiusInMeter: true,
              color: AppColors.primary.withValues(alpha: 0.06),
              borderColor: AppColors.primary.withValues(alpha: 0.5),
              borderStrokeWidth: 1.5,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            if (userLocation != null)
              Marker(
                point: userLocation!,
                width: 22,
                height: 22,
                child: Semantics(
                  label: 'Your location',
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 3),
                      boxShadow: AppShadows.sm,
                    ),
                  ),
                ),
              ),
            ...places.map((place) {
              final selected = place.id == selectedPlace?.id;
              return Marker(
                point: LatLng(place.latitude, place.longitude),
                width: selected ? 56 : 46,
                height: selected ? 56 : 46,
                child: SuitabilityMarker(
                  key: ValueKey('marker-${place.id}'),
                  place: place,
                  result: state.suitabilityFor(place),
                  selected: selected,
                  onTap: () => state.selectPlace(place),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 250),
        child: Material(
          color: AppColors.surface,
          borderRadius: AppRadii.borderRadiusMd,
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          child: state.isSearching
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: LinearProgressIndicator(),
                )
              : places.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('No accessible places found.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  itemCount: math.min(places.length, 5),
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final place = places[index];
                    final fit = state.suitabilityFor(place);
                    return ListTile(
                      leading: Icon(
                        place.category.icon,
                        color: suitabilityColor(fit.suitability),
                      ),
                      title: Text(place.name),
                      subtitle: Text(
                        '${place.category.displayName} - ${fit.suitability.label}',
                      ),
                      onTap: () {
                        context.read<AppState>().selectPlace(place);
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PlaceDetailsScreen(placeId: place.id),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}
