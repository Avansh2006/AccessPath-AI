import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/widgets/app_components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NeedSelectionScreen extends StatelessWidget {
  const NeedSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selectedNeeds = state.profile.accessibilityNeeds;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            key: const ValueKey('need-selection-scroll'),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What accessibility needs should we consider?',
                        style: AppTypography.displayMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Choose what applies now. You can edit this later in your profile.',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      ...AccessibilityNeed.values.map(
                        (need) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: _NeedCard(
                            need: need,
                            selected: selectedNeeds.contains(need),
                          ),
                        ),
                      ),
                      const Spacer(),
                      PrimaryButton(
                        label: 'Open Map',
                        icon: Icons.map,
                        onPressed: selectedNeeds.isEmpty
                            ? null
                            : () {
                                context.read<AppState>().completeOnboarding();
                                // Root route renders MainShell once onboarding
                                // is complete, so return to it.
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NeedCard extends StatelessWidget {
  const _NeedCard({required this.need, required this.selected});

  final AccessibilityNeed need;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: AppRadii.borderRadiusLg,
        onTap: () => context.read<AppState>().toggleNeed(need),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySurface : AppColors.surface,
            borderRadius: AppRadii.borderRadiusLg,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(need.icon, color: AppColors.primary, size: 30),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(need.displayName, style: AppTypography.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(need.description, style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              Checkbox(
                value: selected,
                onChanged: (_) => context.read<AppState>().toggleNeed(need),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
