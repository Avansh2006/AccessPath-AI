import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/shared/models/accessibility_feature.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_review.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: Text(label),
    );
  }
}

class ScoreCard extends StatelessWidget {
  const ScoreCard({
    required this.label,
    required this.score,
    required this.icon,
    this.prominent = false,
    super.key,
  });

  final String label;
  final double score;
  final IconData icon;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scoreColor(score);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: prominent ? color.withValues(alpha: 0.10) : AppColors.surface,
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(color: prominent ? color : AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            score.toStringAsFixed(1),
            style: AppTypography.scoreSmall.copyWith(color: color),
          ),
          const Text('/10', style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

class AccessibilityTag extends StatelessWidget {
  const AccessibilityTag({required this.feature, super.key});

  final AccessibilityFeature feature;

  @override
  Widget build(BuildContext context) {
    final color = switch (feature.status) {
      FeatureStatus.available => AppColors.success,
      FeatureStatus.unavailable => AppColors.error,
      FeatureStatus.unknown => AppColors.warning,
    };
    final prefix = switch (feature.status) {
      FeatureStatus.available => 'Available',
      FeatureStatus.unavailable => 'Not available',
      FeatureStatus.unknown => 'Unknown',
    };
    return Semantics(
      label: '$prefix: ${feature.name}',
      child: Chip(
        avatar: Icon(feature.icon, size: 18, color: color),
        label: Text(feature.name),
        backgroundColor: color.withValues(alpha: 0.10),
        side: BorderSide(color: color.withValues(alpha: 0.30)),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xl,
        bottom: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTypography.headlineSmall)),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class PlaceCard extends StatelessWidget {
  const PlaceCard({
    required this.place,
    required this.onTap,
    this.compact = false,
    this.userLatitude,
    this.userLongitude,
    super.key,
  });

  final Place place;
  final VoidCallback onTap;
  final bool compact;
  final double? userLatitude;
  final double? userLongitude;

  @override
  Widget build(BuildContext context) {
    final features = place.availableFeatures.take(compact ? 2 : 4).toList();
    final distanceLabel = (userLatitude != null && userLongitude != null)
        ? place.distanceKmFrom(userLatitude!, userLongitude!)
        : null;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(place.category.icon, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      place.name,
                      style: AppTypography.titleLarge,
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
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    )
                  else
                    _ScorePill(score: place.friendlyScore),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                distanceLabel == null
                    ? '${place.category.displayName} - ${place.address}'
                    : '${place.category.displayName} - ${_formatDistance(distanceLabel)} - ${place.address}',
                style: AppTypography.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (features.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: features
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
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    required this.review,
    this.onHelpful,
    this.onReport,
    super.key,
  });

  final PlaceReview review;
  final VoidCallback? onHelpful;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primarySurface,
                  foregroundColor: AppColors.primary,
                  child: Text(review.userName.characters.first),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.userName, style: AppTypography.titleMedium),
                      Text(
                        review.reviewerContext.displayLabel,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                _ScorePill(score: review.overallRating),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(review.comment, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _RatingMini(label: 'Staff', value: review.staffInteractionRating),
                _RatingMini(label: 'Comms', value: review.communicationRating),
                _RatingMini(label: 'Access', value: review.physicalAccessibilityRating),
                _RatingMini(label: 'Facilities', value: review.facilitiesRating),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  DateFormat.MMMd().format(review.createdAt),
                  style: AppTypography.bodySmall,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onHelpful,
                  icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                  label: Text('Helpful ${review.helpfulVotes}'),
                ),
                TextButton(
                  onPressed: review.reported ? null : onReport,
                  child: Text(review.reported ? 'Reported' : 'Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTypography.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
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

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.borderRadiusFull,
      ),
      child: Text(
        '${score.toStringAsFixed(1)} Friendly',
        style: AppTypography.labelMedium.copyWith(color: color),
      ),
    );
  }
}

class _RatingMini extends StatelessWidget {
  const _RatingMini({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadii.borderRadiusFull,
      ),
      child: Text('$label ${value!.toStringAsFixed(0)}/10', style: AppTypography.labelMedium),
    );
  }
}
