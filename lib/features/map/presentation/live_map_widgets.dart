import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/map/domain/live_map_explorer.dart';
import 'package:access_map/features/places/presentation/place_details_screen.dart';
import 'package:access_map/shared/models/accessibility_rating.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_review.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Color suitabilityColor(Suitability suitability) => switch (suitability) {
  Suitability.good => AppColors.success,
  Suitability.partial => AppColors.warning,
  Suitability.poor => AppColors.error,
  Suitability.unknown => AppColors.textTertiary,
};

String formatDistance(double km) {
  if (km < 1) {
    return '${(km * 1000).round()} m';
  }
  return '${km.toStringAsFixed(1)} km';
}

/// Map pin coloured by personal suitability. Low-confidence or unrated
/// places render hollow so tentative data never looks like a firm verdict.
class SuitabilityMarker extends StatelessWidget {
  const SuitabilityMarker({
    required this.place,
    required this.result,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Place place;
  final SuitabilityResult result;
  final bool selected;
  final VoidCallback onTap;

  bool get _solid =>
      result.confidence == SuitabilityConfidence.medium ||
      result.confidence == SuitabilityConfidence.high;

  @override
  Widget build(BuildContext context) {
    final color = suitabilityColor(result.suitability);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${place.name}, ${place.category.displayName}, '
          '${result.suitability.label}, ${result.confidence.label}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: _solid ? color : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _solid
                        ? (selected ? AppColors.textPrimary : AppColors.surface)
                        : color,
                    width: selected ? 4 : 3,
                  ),
                  boxShadow: AppShadows.md,
                ),
                child: Icon(
                  place.category.icon,
                  color: _solid ? AppColors.textOnPrimary : color,
                  size: selected ? 26 : 21,
                ),
              ),
            ),
            if (result.confidence == SuitabilityConfidence.high)
              const Positioned(
                right: -2,
                top: -2,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: AppColors.surface,
                  child: Icon(
                    Icons.verified,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SuitabilityLegend extends StatelessWidget {
  const SuitabilityLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget dot(Color color, {bool hollow = false}) => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: hollow ? AppColors.surface : color,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    );
    Widget entry(Widget marker, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        marker,
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        for (final suitability in Suitability.values)
          entry(dot(suitabilityColor(suitability)), suitability.label),
        entry(
          dot(AppColors.textSecondary, hollow: true),
          'Hollow = little evidence',
        ),
        entry(
          const Icon(Icons.verified, size: 14, color: AppColors.primary),
          'High confidence',
        ),
      ],
    );
  }
}

/// Venue card for the selected marker: personal fit, overall score, the five
/// accessibility categories, latest feedback and community photos.
class VenueCard extends StatelessWidget {
  const VenueCard({
    required this.place,
    required this.result,
    required this.relevantCriteria,
    this.userLatitude,
    this.userLongitude,
    this.onClose,
    super.key,
  });

  final Place place;
  final SuitabilityResult result;
  final Set<AccessibilityCriterion> relevantCriteria;
  final double? userLatitude;
  final double? userLongitude;
  final VoidCallback? onClose;

  void _openDetails(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlaceDetailsScreen(placeId: place.id),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final score = place.accessibilityScore;
    PlaceReview? latestReview;
    for (final review in place.reviews) {
      if (review.reported || review.comment.trim().isEmpty) continue;
      if (latestReview == null ||
          review.createdAt.isAfter(latestReview.createdAt)) {
        latestReview = review;
      }
    }
    final distance = userLatitude != null && userLongitude != null
        ? ' · ${formatDistance(place.distanceKmFrom(userLatitude!, userLongitude!))}'
        : '';
    final maxHeight = MediaQuery.sizeOf(context).height * 0.42;
    return Card(
      key: const ValueKey('venue-card'),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(place.category.icon, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        place.name,
                        style: AppTypography.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onClose != null)
                      IconButton(
                        tooltip: 'Close venue card',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close),
                        onPressed: onClose,
                      ),
                  ],
                ),
                Text(
                  '${place.category.displayName}$distance · ${place.source.label}',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                _FitRow(result: result, overall: score.overall),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final criterion in AccessibilityCriterion.values)
                      _CriterionChip(
                        criterion: criterion,
                        value: score.categoryScores[criterion],
                        evidence: score.evidenceFor(criterion),
                        relevant: relevantCriteria.contains(criterion),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Recent feedback', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                if (latestReview == null)
                  const Text(
                    'No community feedback yet.',
                    style: AppTypography.bodySmall,
                  )
                else
                  Text(
                    '"${latestReview.comment}" — ${latestReview.userName}, '
                    '${DateFormat.yMMMd().format(latestReview.createdAt)}',
                    style: AppTypography.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: AppSpacing.md),
                _PhotoRow(photos: place.photos),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _openDetails(context),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('View details'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FitRow extends StatelessWidget {
  const _FitRow({required this.result, required this.overall});

  final SuitabilityResult result;
  final double? overall;

  @override
  Widget build(BuildContext context) {
    final color = suitabilityColor(result.suitability);
    final personal = result.score;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadii.borderRadiusFull,
            border: Border.all(color: color),
          ),
          child: Text(
            personal == null
                ? result.suitability.label
                : '${result.suitability.label} · ${personal.round()}/100 for you',
            style: AppTypography.labelMedium.copyWith(color: color),
          ),
        ),
        Text(
          overall == null
              ? 'No accessibility ratings yet'
              : 'Overall ${overall!.round()}/100 · '
                    '${result.reviewCount} review${result.reviewCount == 1 ? '' : 's'}',
          style: AppTypography.bodySmall,
        ),
        if (result.suitability != Suitability.unknown)
          Text(
            '${result.confidence.label} '
            '(${result.ratedCriteria}/${result.relevantCriteria} of your needs rated)',
            style: AppTypography.bodySmall,
          ),
      ],
    );
  }
}

class _CriterionChip extends StatelessWidget {
  const _CriterionChip({
    required this.criterion,
    required this.value,
    required this.evidence,
    required this.relevant,
  });

  final AccessibilityCriterion criterion;
  final double? value;
  final RequirementEvidence evidence;
  final bool relevant;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (evidence) {
      RequirementEvidence.verified => (
        '${value!.round()}',
        AppColors.success,
      ),
      RequirementEvidence.unavailable => (
        '${value!.round()}',
        AppColors.error,
      ),
      RequirementEvidence.notApplicable => ('N/A', AppColors.textSecondary),
      RequirementEvidence.unverified => ('Unknown', AppColors.textTertiary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadii.borderRadiusSm,
        border: Border.all(
          color: relevant ? AppColors.primary : AppColors.divider,
          width: relevant ? 1.5 : 1,
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${criterion.label}: ',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: relevant ? FontWeight.w700 : null,
              ),
            ),
            TextSpan(
              text: text,
              style: AppTypography.labelMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({required this.photos});

  final List<PlacePhoto> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Text(
        'No community photos yet.',
        style: AppTypography.bodySmall,
      );
    }
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final photo = photos[index];
          final placeholder = Container(
            width: 72,
            color: AppColors.primarySurface,
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_outlined, color: AppColors.primary),
                Text(
                  photo.caption?.isNotEmpty == true
                      ? photo.caption!
                      : 'Community photo',
                  style: AppTypography.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
          final isRemote =
              photo.url.startsWith('https://') ||
              photo.url.startsWith('http://');
          return Semantics(
            label: photo.caption ?? 'Community photo',
            image: true,
            child: ClipRRect(
              borderRadius: AppRadii.borderRadiusSm,
              child: isRemote
                  ? Image.network(
                      photo.url,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => placeholder,
                    )
                  : placeholder,
            ),
          );
        },
      ),
    );
  }
}
