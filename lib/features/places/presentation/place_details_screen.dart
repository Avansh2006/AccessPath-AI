import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/core/utils/accessibility_visibility_policy.dart';
import 'package:access_map/features/reviews/presentation/write_review_screen.dart';
import 'package:access_map/shared/models/accessibility_feature.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_review.dart';
import 'package:access_map/shared/models/user_profile.dart';
import 'package:access_map/shared/widgets/app_components.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PlaceDetailsScreen extends StatelessWidget {
  const PlaceDetailsScreen({required this.placeId, super.key});

  final String placeId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final place = state.places.firstWhere(
      (item) => item.id == placeId,
      orElse: () => state.selectedPlace!,
    );
    final policy = const AccessibilityVisibilityPolicy();
    final profile = state.profile;
    final relevantKeywords = policy.relevantFeatureKeywords(profile);
    final personalizedFeatures = place.availableFeatures.where((feature) {
      final name = feature.name.toLowerCase();
      return relevantKeywords.any(name.contains);
    }).toList();
    final rankedReviews = [...place.reviews]
      ..sort((a, b) {
        final helpfulCompare = b.helpfulVotes.compareTo(a.helpfulVotes);
        if (helpfulCompare != 0) return helpfulCompare;
        return b.createdAt.compareTo(a.createdAt);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(place.name),
        actions: [
          IconButton(
            key: const ValueKey('report-info-button'),
            tooltip: 'Report incorrect information',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => _showPlaceReportSheet(context, place),
          ),
        ],
      ),
      body: ListView(
        key: const ValueKey('place-details-list'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (place.source == PlaceSource.community)
            _CommunityAttributionBanner(place: place),
          _HeroPanel(place: place),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Get Directions',
            icon: Icons.directions,
            onPressed: () async {
              final opened = await context.read<AppState>().openDirections(place);
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Directions are unavailable on this device.')),
                );
              }
            },
          ),
          const SectionHeader('Accessibility overview'),
          if (place.friendlyScore == 0 && place.totalReviews == 0)
            _ProvisionalScoresPanel(policy: policy, profile: profile)
          else ...[
            _ExplainableScore(
            label: 'Friendly Score',
            score: place.friendlyScore,
            icon: Icons.star,
            prominent: true,
            explanation: _friendlyScoreExplanation(place),
          ),
            const SizedBox(height: AppSpacing.md),
          if (policy.showWheelchairScore(profile)) ...[
              _ExplainableScore(
                label: 'Wheelchair-Friendly',
                score: place.wheelchairScore,
                icon: Icons.accessible,
                prominent: true,
                explanation:
                    'Based on ratings from wheelchair users and physically disabled community members, weighted toward physical access factors such as entrances, restrooms and parking.',
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _ExplainableScore(
              label: 'Visual Accessibility',
              score: place.visualAccessibilityScore,
              icon: Icons.visibility,
              prominent: policy.showVisualScore(profile),
              explanation:
                  'How well blind and visually impaired visitors rate navigation, signage, staff support and sensory guidance here.',
            ),
            const SizedBox(height: AppSpacing.md),
            _ExplainableScore(
              label: 'Hearing Friendly',
              score: place.hearingAccessibilityScore,
              icon: Icons.hearing,
              prominent: policy.showHearingScore(profile),
              explanation:
                  'How well deaf and hard-of-hearing visitors rate visual announcements, written communication and staff awareness here.',
            ),
            const SizedBox(height: AppSpacing.md),
            _ExplainableScore(
              label: 'Communication Friendly',
              score: place.communicationScore,
              icon: Icons.chat,
              prominent: policy.showCommunicationScore(profile),
              explanation:
                  'How well staff support written, visual and patient communication for visitors who cannot speak or talk.',
            ),
          ],
          if (personalizedFeatures.isNotEmpty) ...[
            const SectionHeader('Why this may work for you'),
            ...personalizedFeatures.take(4).map(
                  (feature) => _ConfirmationRow(feature: feature),
                ),
          ],
          const SectionHeader('Accessibility features'),
          ...place.accessibilityFeatures.map(
            (feature) => _ConfirmableFeatureRow(
              feature: feature,
              onConfirm: feature.status == FeatureStatus.available
                  ? () => context.read<AppState>().confirmFeature(place, feature)
                  : null,
            ),
          ),
          const SectionHeader('Community confidence'),
          _ConfidencePanel(place: place),
          SectionHeader(
            'Reviews',
            action: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WriteReviewScreen(place: place),
                ),
              ),
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Write'),
            ),
          ),
          ...rankedReviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ReviewCard(
                review: review,
                onHelpful: () => context.read<AppState>().markReviewHelpful(place, review),
                onReport: () => _showReportSheet(context, place, review),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyScoreExplanation(Place place) {
    return 'Based on:\n'
        '• ${place.totalReviews} community reviews\n'
        '• Staff interaction and assistance\n'
        '• Accessibility facilities available\n'
        '• ${place.communityConfirmations} community confirmations\n'
        '• Recent reports';
  }

  void _showPlaceReportSheet(BuildContext context, Place place) {
    final state = context.read<AppState>();
    final alreadyReported = state.hasReportedPlace(place.id);
    final reasons = [
      'Accessibility feature no longer exists',
      'Information is incorrect',
      'Place has changed',
      'Duplicate location',
      'Other',
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const Text('Report accessibility information',
                style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Help the community keep information accurate.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (alreadyReported)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: AppRadii.borderRadiusMd,
                ),
                child: Text(
                  'You reported: ${state.reportReasonFor(place.id)}',
                  style: AppTypography.bodyMedium,
                ),
              )
            else
              ...reasons.map(
                (reason) => ListTile(
                  title: Text(reason),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.read<AppState>().reportPlaceInfo(place, reason);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Reported: $reason. Thank you for helping.')),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context, Place place, PlaceReview review) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final reasons = ['Inaccurate', 'Offensive', 'Spam', 'Irrelevant', 'Review bombing'];
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const Text('Report review', style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            ...reasons.map(
              (reason) => ListTile(
                title: Text(reason),
                onTap: () {
                  context.read<AppState>().reportReview(place, review);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reported as $reason.')),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primarySurface,
                foregroundColor: AppColors.primary,
                child: Icon(place.category.icon, size: 30),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: AppTypography.headlineLarge),
                    Text(place.category.displayName, style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(place.description, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          _InfoLine(icon: Icons.place_outlined, text: place.address),
          if (place.phone != null) _InfoLine(icon: Icons.phone_outlined, text: place.phone!),
          if (place.website != null) _InfoLine(icon: Icons.language, text: place.website!),
          if (place.photos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _PhotoStrip(photos: place.photos),
          ],
        ],
      ),
    );
  }
}

/// Community-added banner (#51, #52) — shown only for community places.
class _CommunityAttributionBanner extends StatelessWidget {
  const _CommunityAttributionBanner({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final addedAt = place.createdAt == null
        ? null
        : DateFormat.yMMMMd().format(place.createdAt!);
    return Container(
      key: const ValueKey('community-banner'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.volunteer_activism, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              addedAt == null
                  ? 'Added by the community'
                  : 'Added by the community - $addedAt',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Provisional score state for places with no community ratings yet
/// (#40, #41) — honest labels instead of fake numbers.
class _ProvisionalScoresPanel extends StatelessWidget {
  const _ProvisionalScoresPanel({
    required this.policy,
    required this.profile,
  });

  final AccessibilityVisibilityPolicy policy;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('provisional-scores-panel'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadii.borderRadiusMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_empty, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Friendly Score - New',
                  style: AppTypography.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Not enough community ratings yet. This place was recently added; '
            'scores appear as the community reviews and confirms it.',
            style: AppTypography.bodyMedium,
          ),
          if (policy.showWheelchairScore(profile)) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Wheelchair-Friendly - awaiting community ratings',
              style: AppTypography.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// Community photo strip with captions (#20).
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos});

  final List<PlacePhoto> photos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${photos.length} community photo${photos.length == 1 ? '' : 's'}',
          style: AppTypography.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final photo = photos[index];
              return Container(
                width: 96,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: AppRadii.borderRadiusMd,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_outlined,
                        color: AppColors.primary, size: 28),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      photo.caption?.isNotEmpty == true
                          ? photo.caption!
                          : 'Community photo',
                      style: AppTypography.labelSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({required this.feature});

  final AccessibilityFeature feature;

  @override
  Widget build(BuildContext context) {
    final lastConfirmed = feature.lastConfirmed == null
        ? 'No recent date'
        : DateFormat.yMMMd().format(feature.lastConfirmed!);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check_circle, color: AppColors.success),
      title: Text(feature.name),
      subtitle: Text('Confirmed by ${feature.confirmationCount} users - $lastConfirmed'),
    );
  }
}

/// Score card with progress bar; tapping shows the score explanation.
class _ExplainableScore extends StatelessWidget {
  const _ExplainableScore({
    required this.label,
    required this.score,
    required this.icon,
    required this.explanation,
    this.prominent = false,
  });

  final String label;
  final double score;
  final IconData icon;
  final String explanation;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadii.borderRadiusMd,
      onTap: () => _showExplanation(context),
      child: Column(
        children: [
          ScoreCard(
            label: label,
            score: score,
            icon: icon,
            prominent: prominent,
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadii.borderRadiusFull,
            child: LinearProgressIndicator(
              value: score / 10,
              minHeight: 6,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.scoreColor(score),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExplanation(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$label explanation', style: AppTypography.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${score.toStringAsFixed(1)} / 10',
                style: AppTypography.scoreDisplay.copyWith(
                  color: AppColors.scoreColor(score),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(explanation, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// A feature row with confirmation info and an optional Confirm action.
class _ConfirmableFeatureRow extends StatelessWidget {
  const _ConfirmableFeatureRow({
    required this.feature,
    required this.onConfirm,
  });

  final AccessibilityFeature feature;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (feature.status) {
      FeatureStatus.available => AppColors.success,
      FeatureStatus.unavailable => AppColors.error,
      FeatureStatus.unknown => AppColors.warning,
    };
    final statusSymbol = feature.status.symbol;
    final lastConfirmed = feature.lastConfirmed == null
        ? null
        : DateFormat.yMMMd().format(feature.lastConfirmed!);
    final subtitle = feature.status == FeatureStatus.available
        ? 'Confirmed by ${feature.confirmationCount} users'
            '${lastConfirmed != null ? ' - last $lastConfirmed' : ''}'
        : feature.status == FeatureStatus.unavailable
            ? 'Reported not available here'
            : 'Not yet verified by the community';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(statusSymbol,
          style: AppTypography.titleLarge.copyWith(color: statusColor)),
      title: Text(feature.name, style: AppTypography.titleMedium),
      subtitle: Text(subtitle, style: AppTypography.bodySmall),
      trailing: onConfirm == null
          ? null
          : TextButton(
              onPressed: onConfirm,
              child: const Text('Confirm'),
            ),
    );
  }
}

class _ConfidencePanel extends StatelessWidget {
  const _ConfidencePanel({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final verified = place.lastVerified == null
        ? 'Not recently verified'
        : DateFormat.yMMMd().format(place.lastVerified!);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: AppRadii.borderRadiusMd,
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: AppColors.info),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '${place.communityConfirmations} confirmations. Last verified by community: $verified.',
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
