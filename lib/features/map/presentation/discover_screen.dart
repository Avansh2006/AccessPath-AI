import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/places/presentation/place_details_screen.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_category.dart';
import 'package:access_map/shared/widgets/access_search_bar.dart';
import 'package:access_map/shared/widgets/app_components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  PlaceCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allPlaces = state.visiblePlaces;
    final filtered = _selectedCategory == null
        ? allPlaces
        : allPlaces.where((p) => p.category == _selectedCategory).toList();
    final popular = [...allPlaces]
      ..sort((a, b) => b.communityConfirmations.compareTo(a.communityConfirmations));
    final highlyRated = [...allPlaces]
      ..sort((a, b) => b.friendlyScore.compareTo(a.friendlyScore));
    final recentlyAdded = allPlaces
        .where((p) => p.source == PlaceSource.community)
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    final showingCategorySections = _selectedCategory == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: context.read<AppState>().loadPlaces,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const AccessSearchBar(),
              const SizedBox(height: AppSpacing.lg),
              _ProfileLens(needs: state.profile.accessibilityNeeds),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      icon: Icons.apps,
                      label: 'All',
                      selected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    ...PlaceCategory.values.map(
                      (category) => _CategoryChip(
                        icon: category.icon,
                        label: category.displayName,
                        selected: _selectedCategory == category,
                        onTap: () => setState(() => _selectedCategory = category),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.isLoadingPlaces)
                const Center(child: CircularProgressIndicator())
              else if (filtered.isEmpty)
                const EmptyState(
                  title: 'No accessible places found nearby',
                  message: 'Try expanding your search or removing a filter.',
                )
              else ...[
                if (showingCategorySections) ...[
                  if (recentlyAdded.isNotEmpty) ...[
                    const SectionHeader('Recently Added'),
                    ...recentlyAdded.take(3).map(
                          (place) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: PlaceCard(
                              place: place,
                              onTap: () => _openDetails(context, place),
                            ),
                          ),
                        ),
                  ],
                  const SectionHeader('Popular Near You'),
                  SizedBox(
                    height: 190,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: popular.take(6).length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) => SizedBox(
                        width: 250,
                        child: _CompactPlaceTile(
                          place: popular[index],
                          subtitle:
                              '${popular[index].communityConfirmations} confirmations',
                        ),
                      ),
                    ),
                  ),
                  const SectionHeader('Highly Rated by Community'),
                  ...highlyRated.take(5).map(
                        (place) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: PlaceCard(
                            place: place,
                            onTap: () => _openDetails(context, place),
                          ),
                        ),
                      ),
                ] else ...[
                  const SectionHeader('Matching Places'),
                  ...filtered.map(
                    (place) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: PlaceCard(
                        place: place,
                        onTap: () => _openDetails(context, place),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, Place place) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaceDetailsScreen(placeId: place.id),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _CompactPlaceTile extends StatelessWidget {
  const _CompactPlaceTile({required this.place, required this.subtitle});

  final Place place;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: AppRadii.borderRadiusMd,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PlaceDetailsScreen(placeId: place.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    foregroundColor: AppColors.primary,
                    child: Icon(place.category.icon, size: 20),
                  ),
                  const Spacer(),
                  _ScoreBadge(score: place.friendlyScore),
                ],
              ),
              const Spacer(),
              Text(
                place.name,
                style: AppTypography.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.borderRadiusFull,
      ),
      child: Text(
        score.toStringAsFixed(1),
        style: AppTypography.labelMedium.copyWith(color: color),
      ),
    );
  }
}

class _ProfileLens extends StatelessWidget {
  const _ProfileLens({required this.needs});

  final List<AccessibilityNeed> needs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: AppRadii.borderRadiusMd,
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              needs.isEmpty
                  ? 'Showing community accessibility intelligence.'
                  : 'Prioritizing ${needs.map((need) => need.displayName).join(', ')} signals.',
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
