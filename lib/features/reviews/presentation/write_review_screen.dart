import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
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
  double _overall = 8;
  double _staff = 8;
  double _communication = 8;
  double _assistance = 8;
  double _physical = 8;
  double _facilities = 8;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _commentController.text.trim().length >= 12 && !_submitting;
    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: ListView(
        key: const ValueKey('write-review-list'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(widget.place.name, style: AppTypography.headlineLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Rate the visit from your accessibility context.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SectionHeader('Accessibility ratings'),
          _RatingSlider(label: 'Overall experience', value: _overall, onChanged: (v) => setState(() => _overall = v)),
          _RatingSlider(label: 'Staff interaction', value: _staff, onChanged: (v) => setState(() => _staff = v)),
          _RatingSlider(label: 'Communication', value: _communication, onChanged: (v) => setState(() => _communication = v)),
          _RatingSlider(label: 'Assistance', value: _assistance, onChanged: (v) => setState(() => _assistance = v)),
          _RatingSlider(label: 'Physical accessibility', value: _physical, onChanged: (v) => setState(() => _physical = v)),
          _RatingSlider(label: 'Facilities available', value: _facilities, onChanged: (v) => setState(() => _facilities = v)),
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
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo uploads are prepared for a future backend.')),
              );
            },
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Add Photo'),
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
    await context.read<AppState>().addReview(
          place: widget.place,
          overall: _overall,
          staff: _staff,
          communication: _communication,
          assistance: _assistance,
          physical: _physical,
          facilities: _facilities,
          comment: _commentController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('+5 Community Points for your review.')),
    );
    Navigator.of(context).pop();
  }
}

class _RatingSlider extends StatelessWidget {
  const _RatingSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTypography.titleMedium)),
              Text('${value.round()}/10', style: AppTypography.titleMedium),
            ],
          ),
          Slider(
            min: 1,
            max: 10,
            divisions: 9,
            value: value,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
