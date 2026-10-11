import 'package:flutter/material.dart';

/// Extensible accessibility need enum.
/// Only cannotTalk, cannotSpeak, cannotSee are exposed in MVP onboarding.
enum AccessibilityNeed {
  cannotTalk,
  cannotSpeak,
  cannotSee,
  physicallyDisabled,
  deaf,
  visuallyImpaired,
  wheelchairUser,
  other;

  String get displayName {
    switch (this) {
      case AccessibilityNeed.cannotTalk:
        return "Can't Talk";
      case AccessibilityNeed.cannotSpeak:
        return "Can't Speak";
      case AccessibilityNeed.cannotSee:
        return "Can't See";
      case AccessibilityNeed.physicallyDisabled:
        return 'Physically Disabled';
      case AccessibilityNeed.deaf:
        return 'Deaf / Hearing Impaired';
      case AccessibilityNeed.visuallyImpaired:
        return 'Visually Impaired';
      case AccessibilityNeed.wheelchairUser:
        return 'Wheelchair User';
      case AccessibilityNeed.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case AccessibilityNeed.cannotTalk:
        return 'I have difficulty with verbal communication.';
      case AccessibilityNeed.cannotSpeak:
        return 'I am unable to speak or have speech impairment.';
      case AccessibilityNeed.cannotSee:
        return 'I have visual impairment or blindness.';
      case AccessibilityNeed.physicallyDisabled:
        return 'I have physical mobility challenges.';
      case AccessibilityNeed.deaf:
        return 'I have hearing impairment or deafness.';
      case AccessibilityNeed.visuallyImpaired:
        return 'I have partial visual impairment.';
      case AccessibilityNeed.wheelchairUser:
        return 'I use a wheelchair for mobility.';
      case AccessibilityNeed.other:
        return 'I have other accessibility needs.';
    }
  }

  IconData get icon {
    switch (this) {
      case AccessibilityNeed.cannotTalk:
        return Icons.voice_over_off;
      case AccessibilityNeed.cannotSpeak:
        return Icons.speaker_notes_off;
      case AccessibilityNeed.cannotSee:
        return Icons.visibility_off;
      case AccessibilityNeed.physicallyDisabled:
        return Icons.accessible;
      case AccessibilityNeed.deaf:
        return Icons.hearing_disabled;
      case AccessibilityNeed.visuallyImpaired:
        return Icons.remove_red_eye;
      case AccessibilityNeed.wheelchairUser:
        return Icons.accessible;
      case AccessibilityNeed.other:
        return Icons.more_horiz;
    }
  }

  /// The MVP onboarding only shows these three options.
  static List<AccessibilityNeed> get mvpOptions => [
        cannotTalk,
        cannotSpeak,
        cannotSee,
      ];

  /// Whether this need is related to physical/wheelchair accessibility.
  bool get isPhysicalAccessibility =>
      this == physicallyDisabled || this == wheelchairUser;
}
