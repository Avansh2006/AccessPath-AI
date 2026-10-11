import 'package:flutter/material.dart';

/// Category of accessibility feature for grouping.
enum AccessibilityCategory {
  physical,
  visual,
  hearing,
  communication;

  String get displayName {
    switch (this) {
      case AccessibilityCategory.physical:
        return 'Physical Accessibility';
      case AccessibilityCategory.visual:
        return 'Visual Accessibility';
      case AccessibilityCategory.hearing:
        return 'Hearing Accessibility';
      case AccessibilityCategory.communication:
        return 'Communication Accessibility';
    }
  }

  IconData get icon {
    switch (this) {
      case AccessibilityCategory.physical:
        return Icons.accessible;
      case AccessibilityCategory.visual:
        return Icons.visibility;
      case AccessibilityCategory.hearing:
        return Icons.hearing;
      case AccessibilityCategory.communication:
        return Icons.chat;
    }
  }
}

/// Status of an accessibility feature at a place.
enum FeatureStatus {
  available,
  unavailable,
  unknown;

  String get symbol {
    switch (this) {
      case FeatureStatus.available:
        return '✓';
      case FeatureStatus.unavailable:
        return '✗';
      case FeatureStatus.unknown:
        return '?';
    }
  }
}

/// An accessibility feature for a place, with community confirmation data.
class AccessibilityFeature {
  final String id;
  final String name;
  final IconData icon;
  final AccessibilityCategory category;
  final FeatureStatus status;
  final int confirmationCount;
  final DateTime? lastConfirmed;

  const AccessibilityFeature({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    required this.status,
    this.confirmationCount = 0,
    this.lastConfirmed,
  });

  AccessibilityFeature copyWith({
    FeatureStatus? status,
    int? confirmationCount,
    DateTime? lastConfirmed,
  }) {
    return AccessibilityFeature(
      id: id,
      name: name,
      icon: icon,
      category: category,
      status: status ?? this.status,
      confirmationCount: confirmationCount ?? this.confirmationCount,
      lastConfirmed: lastConfirmed ?? this.lastConfirmed,
    );
  }
}
