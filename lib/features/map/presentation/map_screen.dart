import 'dart:math' as math;

import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/contribute/presentation/add_location_screen.dart';
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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  PlaceCategory? _categoryFilter;
  bool _highlyFriendlyOnly = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final places = state.rankForRequirements(
      _filteredPlaces(state.visiblePlaces),
    );
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: state.isLoadingPlaces
                ? const Center(child: CircularProgressIndicator())
                : _AccessibleMap(
                    key: ValueKey('${state.mapLatitude},${state.mapLongitude}'),
                    places: places,
                    selectedPlace: state.selectedPlace,
                    center: LatLng(state.mapLatitude, state.mapLongitude),
                  ),
          ),
          Positioned(
            top: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Column(
              children: [
                const AccessSearchBar(),
                if (state.searchQuery.isNotEmpty || state.isSearching)
                  _SearchResults(places: places),
              ],
            ),
          ),
          Positioned(
            top: 92,
            right: AppSpacing.lg,
            child: FloatingActionButton.small(
              heroTag: 'filters',
              tooltip: 'Filters',
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              onPressed: () => _showFilters(context),
              child: const Icon(Icons.tune),
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            bottom: state.selectedPlace == null ? AppSpacing.lg : 190,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  onPressed: () async {
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
                  child: const Icon(Icons.my_location),
                ),
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
          if (state.selectedPlace != null)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: PlacePreviewSheet(
                place: state.selectedPlace!,
                userLatitude: 15.4909,
                userLongitude: 73.8278,
              ),
            ),
        ],
      ),
    );
  }

  List<Place> _filteredPlaces(List<Place> places) {
    return places.where((place) {
      if (_categoryFilter != null && place.category != _categoryFilter) {
        return false;
      }
      if (_highlyFriendlyOnly && place.friendlyScore < 8.5) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
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
                  const SizedBox(height: AppSpacing.lg),
                  SwitchListTile(
                    value: _highlyFriendlyOnly,
                    onChanged: (value) {
                      setState(() => _highlyFriendlyOnly = value);
                      setModalState(() {});
                    },
                    title: const Text('Highly friendly'),
                    subtitle: const Text('Friendly Score 8.5 and above'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _categoryFilter == null,
                        onSelected: (_) {
                          setState(() => _categoryFilter = null);
                          setModalState(() {});
                        },
                      ),
                      ...PlaceCategory.values.map(
                        (category) => ChoiceChip(
                          avatar: Icon(category.icon, size: 18),
                          label: Text(category.displayName),
                          selected: _categoryFilter == category,
                          onSelected: (_) {
                            setState(() => _categoryFilter = category);
                            setModalState(() {});
                          },
                        ),
                      ),
                    ],
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

class _AccessibleMap extends StatelessWidget {
  const _AccessibleMap({
    super.key,
    required this.places,
    required this.selectedPlace,
    required this.center,
  });

  final List<Place> places;
  final Place? selectedPlace;
  final LatLng center;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 11),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.access_map',
        ),
        MarkerLayer(
          markers: places.map((place) {
            final selected = place.id == selectedPlace?.id;
            return Marker(
              point: LatLng(place.latitude, place.longitude),
              width: selected ? 58 : 48,
              height: selected ? 58 : 48,
              child: GestureDetector(
                onTap: () => context.read<AppState>().selectPlace(place),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.secondary : AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 3),
                    boxShadow: AppShadows.md,
                  ),
                  child: Icon(
                    place.category.icon,
                    color: AppColors.textOnPrimary,
                    size: selected ? 28 : 23,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class PlacePreviewSheet extends StatelessWidget {
  const PlacePreviewSheet({
    required this.place,
    this.userLatitude,
    this.userLongitude,
    super.key,
  });

  final Place place;
  final double? userLatitude;
  final double? userLongitude;

  @override
  Widget build(BuildContext context) {
    final relevant = place.availableFeatures.take(3).toList();
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: AppRadii.borderRadiusMd,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PlaceDetailsScreen(placeId: place.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      place.name,
                      style: AppTypography.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (place.friendlyScore == 0 && place.totalReviews == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: AppRadii.borderRadiusFull,
                      ),
                      child: Text(
                        'New',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    Text(
                      '${place.friendlyScore.toStringAsFixed(1)} Friendly',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.scoreColor(place.friendlyScore),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${place.category.displayName}'
                '${userLatitude != null && userLongitude != null ? ' - ${_formatDistance(place.distanceKmFrom(userLatitude!, userLongitude!))}' : ''}'
                ' - ${place.communityConfirmations} confirmations',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: relevant
                    .map(
                      (feature) => Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(feature.icon, size: 16),
                        label: Text(feature.name),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDistance(double km) {
  if (km < 1) {
    return '${(km * 1000).round()} m';
  }
  return '${km.toStringAsFixed(1)} km';
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
                    return ListTile(
                      leading: Icon(place.category.icon),
                      title: Text(place.name),
                      subtitle: Text(
                        '${place.category.displayName} - Friendly ${place.friendlyScore.toStringAsFixed(1)}',
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
