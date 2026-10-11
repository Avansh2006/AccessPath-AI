import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/contribute/presentation/add_location_screen.dart';
import 'package:access_map/features/places/presentation/place_details_screen.dart';
import 'package:access_map/features/reviews/presentation/write_review_screen.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Contribute tab — the community hub. Primary action: add a new location.
class ContributionsScreen extends StatelessWidget {
  const ContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Contribute')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Help make places more accessible',
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Every contribution helps someone plan a visit with confidence.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ActionCard(
            key: const ValueKey('add-location-card'),
            icon: Icons.add_location_alt,
            title: 'Add a New Location',
            subtitle: 'Put an accessible place on the community map',
            highlight: true,
            onTap: () => _openAddLocation(context),
          ),
          _ActionCard(
            icon: Icons.fact_check_outlined,
            title: 'Add Accessibility Information',
            subtitle: 'Confirm or update what you know about a place',
            onTap: () => _openAddLocation(context),
          ),
          _ActionCard(
            icon: Icons.rate_review_outlined,
            title: 'Write a Review',
            subtitle: 'Share how a place worked for you',
            onTap: () => _showPickPlaceSheet(
              context,
              (place) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WriteReviewScreen(place: place),
                ),
              ),
            ),
          ),
          _ActionCard(
            icon: Icons.verified_outlined,
            title: 'Confirm Existing Information',
            subtitle: 'Verify accessibility features you have seen',
            onTap: () => _showPickPlaceSheet(
              context,
              (place) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlaceDetailsScreen(placeId: place.id),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadii.borderRadiusLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.communityPoints.toString(),
                  style: AppTypography.scoreDisplay.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                Text(
                  'Community Points',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Locations',
                  value: profile.locationCount,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _MetricTile(label: 'Reviews', value: profile.reviewCount)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _MetricTile(label: 'Updates', value: profile.accessibilityUpdates)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _MetricTile(label: 'Photos', value: profile.photoCount)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Recent Activity', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          ...profile.recentActivity.map(
            (activity) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.successLight,
                  foregroundColor: AppColors.success,
                  child: Text('+${activity.pointsEarned}'),
                ),
                title: Text(activity.description),
                subtitle: Text(DateFormat.yMMMd().add_jm().format(activity.timestamp)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddLocation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AddLocationScreen()),
    );
  }

  void _showPickPlaceSheet(
    BuildContext context,
    void Function(Place place) onPicked,
  ) {
    final places = context.read<AppState>().places;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('Choose a place', style: AppTypography.headlineSmall),
            ),
            ...places.map(
              (place) => ListTile(
                leading: Icon(place.category.icon, color: AppColors.primary),
                title: Text(place.name),
                subtitle: Text(place.category.displayName),
                onTap: () {
                  Navigator.of(context).pop();
                  onPicked(place);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.borderRadiusMd,
        side: BorderSide(
          color: highlight ? AppColors.primary : AppColors.divider,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: AppRadii.borderRadiusMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: highlight ? AppColors.primary : AppColors.primarySurface,
                  borderRadius: AppRadii.borderRadiusMd,
                ),
                child: Icon(
                  icon,
                  color: highlight ? AppColors.textOnPrimary : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(value.toString(), style: AppTypography.headlineMedium),
          Text(label, style: AppTypography.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
