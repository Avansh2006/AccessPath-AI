import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/onboarding/presentation/need_selection_screen.dart';
import 'package:access_map/shared/models/travel_mode.dart';
import 'package:access_map/shared/widgets/app_components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selectedMode = state.hasSelectedTravelMode
        ? state.profile.travelMode
        : null;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Text(
                        'Welcome to AccessPath AI',
                        style: AppTypography.displayMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Built by BIT for BYTE. Tell us how you plan to travel so place guidance can adapt to you.',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      _ModeCard(
                        mode: TravelMode.paAssisted,
                        selected: selectedMode == TravelMode.paAssisted,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ModeCard(
                        mode: TravelMode.solo,
                        selected: selectedMode == TravelMode.solo,
                      ),
                      const Spacer(),
                      PrimaryButton(
                        label: 'Continue',
                        icon: Icons.arrow_forward,
                        onPressed: selectedMode == null
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const NeedSelectionScreen(),
                                  ),
                                );
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

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.selected});

  final TravelMode mode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${mode.displayName}. ${mode.description}',
      child: InkWell(
        borderRadius: AppRadii.borderRadiusLg,
        onTap: () => context.read<AppState>().selectTravelMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySurface : AppColors.surface,
            borderRadius: AppRadii.borderRadiusLg,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected ? AppShadows.md : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: selected
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                foregroundColor: selected
                    ? AppColors.textOnPrimary
                    : AppColors.primary,
                child: Icon(
                  mode == TravelMode.paAssisted
                      ? Icons.handshake
                      : Icons.person_pin_circle,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mode.displayName, style: AppTypography.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(mode.description, style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
