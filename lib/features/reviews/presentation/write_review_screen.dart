import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/shared/models/accessibility_rating.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/widgets/app_components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({required this.place, super.key});

  final Place place;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _commentController = TextEditingController();
  final Map<AccessibilityCriterion, AccessibilityRating> _ratings = {
    for (final criterion in AccessibilityCriterion.values)
      criterion: AccessibilityRating.rated(3),
  };
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAnswered = _ratings.values.any(
      (rating) => rating.status != AccessibilityRatingStatus.unknown,
    );
    final canSubmit =
        hasAnswered &&
        _commentController.text.trim().length >= 12 &&
        !_submitting;
    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: ListView(
        key: const ValueKey('write-review-list'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(widget.place.name, style: AppTypography.headlineLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Rate only what you observed. Unknown is never counted as accessible.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SectionHeader('Accessibility ratings (0–5)'),
          ...AccessibilityCriterion.values.map(
            (criterion) => _CriterionRating(
              criterion: criterion,
              rating: _ratings[criterion]!,
              onChanged: (rating) =>
                  setState(() => _ratings[criterion] = rating),
            ),
          ),
          const SectionHeader('Tell the community'),
          TextField(
            controller: _commentController,
            maxLines: 5,
            minLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'What should someone with similar needs expect here?',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: _submitting ? 'Submitting...' : 'Submit Review',
            icon: Icons.check,
            onPressed: canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await context.read<AppState>().addReview(
        place: widget.place,
        ratings: Map.unmodifiable(_ratings),
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('+5 Community Points for your review.')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review could not be saved. Please try again.'),
        ),
      );
    }
  }
}

class _CriterionRating extends StatelessWidget {
  const _CriterionRating({
    required this.criterion,
    required this.rating,
    required this.onChanged,
  });

  final AccessibilityCriterion criterion;
  final AccessibilityRating rating;
  final ValueChanged<AccessibilityRating> onChanged;

  @override
  Widget build(BuildContext context) {
    final value = rating.value ?? 3;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(criterion.label, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<AccessibilityRatingStatus>(
              segments: const [
                ButtonSegment(
                  value: AccessibilityRatingStatus.rated,
                  label: Text('Rate'),
                ),
                ButtonSegment(
                  value: AccessibilityRatingStatus.unknown,
                  label: Text('Unknown'),
                ),
                ButtonSegment(
                  value: AccessibilityRatingStatus.notApplicable,
                  label: Text('N/A'),
                ),
              ],
              selected: {rating.status},
              onSelectionChanged: (selection) {
                final status = selection.first;
                onChanged(switch (status) {
                  AccessibilityRatingStatus.rated => AccessibilityRating.rated(
                    value,
                  ),
                  AccessibilityRatingStatus.unknown =>
                    const AccessibilityRating.unknown(),
                  AccessibilityRatingStatus.notApplicable =>
                    const AccessibilityRating.notApplicable(),
                });
              },
            ),
            if (rating.status == AccessibilityRatingStatus.rated) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      min: 0,
                      max: 5,
                      divisions: 5,
                      value: value,
                      label: value.round().toString(),
                      onChanged: (next) =>
                          onChanged(AccessibilityRating.rated(next)),
                    ),
                  ),
                  Text('${value.round()}/5'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
