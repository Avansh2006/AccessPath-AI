import 'package:flutter/material.dart';
import 'package:access_map/shared/models/accessibility_feature.dart';

/// One selectable option in the Add Location accessibility step.
/// [catalogId] groups options by theme so confirm/lookup can reuse them.
class FeatureOption {
  final String id;
  final String name;
  final IconData icon;
  final AccessibilityCategory category;

  const FeatureOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
  });
}

/// Staff helpfulness — accessibility is more than physical features.
enum StaffAssistanceLevel {
  veryHelpful('Very helpful'),
  helpful('Helpful'),
  neutral('Neutral'),
  limited('Limited'),
  notAvailable('Not available'),
  notSure('Not sure');

  const StaffAssistanceLevel(this.label);
  final String label;
}

/// Curated options for the submission flow, organized per the spec:
/// physical, visual, hearing and communication are distinct categories.
class AccessibilityFeatureCatalog {
  AccessibilityFeatureCatalog._();

  static const List<FeatureOption> physical = [
    FeatureOption(id: 'step-free', name: 'Step-free entrance', icon: Icons.door_front_door, category: AccessibilityCategory.physical),
    FeatureOption(id: 'ramp', name: 'Ramp', icon: Icons.accessible, category: AccessibilityCategory.physical),
    FeatureOption(id: 'elevator', name: 'Elevator', icon: Icons.elevator, category: AccessibilityCategory.physical),
    FeatureOption(id: 'restroom', name: 'Accessible restroom', icon: Icons.wc, category: AccessibilityCategory.physical),
    FeatureOption(id: 'parking', name: 'Accessible parking', icon: Icons.local_parking, category: AccessibilityCategory.physical),
    FeatureOption(id: 'wide-entrance', name: 'Wide entrance', icon: Icons.door_sliding, category: AccessibilityCategory.physical),
    FeatureOption(id: 'handrails', name: 'Handrails', icon: Icons.ramp_left, category: AccessibilityCategory.physical),
    FeatureOption(id: 'seating', name: 'Accessible seating', icon: Icons.event_seat, category: AccessibilityCategory.physical),
    FeatureOption(id: 'low-counter', name: 'Low counter', icon: Icons.vertical_align_bottom, category: AccessibilityCategory.physical),
  ];

  static const List<FeatureOption> visual = [
    FeatureOption(id: 'braille', name: 'Braille', icon: Icons.menu_book, category: AccessibilityCategory.visual),
    FeatureOption(id: 'tactile', name: 'Tactile guidance', icon: Icons.touch_app, category: AccessibilityCategory.visual),
    FeatureOption(id: 'audible', name: 'Audible announcements', icon: Icons.headphones, category: AccessibilityCategory.visual),
    FeatureOption(id: 'staff-assistance', name: 'Staff assistance', icon: Icons.support_agent, category: AccessibilityCategory.visual),
    FeatureOption(id: 'clear-signage', name: 'Clear signage', icon: Icons.signpost, category: AccessibilityCategory.visual),
    FeatureOption(id: 'high-contrast', name: 'High-contrast signage', icon: Icons.contrast, category: AccessibilityCategory.visual),
    FeatureOption(id: 'audio-info', name: 'Audio information', icon: Icons.record_voice_over, category: AccessibilityCategory.visual),
  ];

  static const List<FeatureOption> hearing = [
    FeatureOption(id: 'visual-announcements', name: 'Visual announcements', icon: Icons.tv, category: AccessibilityCategory.hearing),
    FeatureOption(id: 'written-instructions', name: 'Written instructions', icon: Icons.edit_note, category: AccessibilityCategory.hearing),
    FeatureOption(id: 'visual-signage', name: 'Clear visual signage', icon: Icons.signpost, category: AccessibilityCategory.hearing),
    FeatureOption(id: 'text-communication', name: 'Text-based communication', icon: Icons.chat, category: AccessibilityCategory.hearing),
    FeatureOption(id: 'sign-language', name: 'Sign-language support', icon: Icons.sign_language, category: AccessibilityCategory.hearing),
    FeatureOption(id: 'visual-emergency', name: 'Visual emergency information', icon: Icons.emergency, category: AccessibilityCategory.hearing),
  ];

  static const List<FeatureOption> communication = [
    FeatureOption(id: 'written-communication', name: 'Staff comfortable with written communication', icon: Icons.edit_note, category: AccessibilityCategory.communication),
    FeatureOption(id: 'text-ordering', name: 'Text-based communication available', icon: Icons.sms_outlined, category: AccessibilityCategory.communication),
    FeatureOption(id: 'digital-communication', name: 'Digital ordering / communication', icon: Icons.devices, category: AccessibilityCategory.communication),
    FeatureOption(id: 'patient-staff', name: 'Staff willing to communicate patiently', icon: Icons.volunteer_activism, category: AccessibilityCategory.communication),
  ];

  static const List<FeatureOption> all = [
    ...physical,
    ...visual,
    ...hearing,
    ...communication,
  ];

  /// Resolve an option id back to its catalog entry (for persisted places).
  static FeatureOption? byId(String id) {
    for (final option in all) {
      if (option.id == id) return option;
    }
    return null;
  }
}
