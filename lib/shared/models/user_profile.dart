import 'accessibility_need.dart';
import 'travel_mode.dart';

/// Activity type for community contributions.
enum ContributionType {
  review,
  accessibilityUpdate,
  photoUpload,
  confirmation,
  helpfulVote,
  locationAdd;

  String get displayName {
    switch (this) {
      case ContributionType.review:
        return 'Review';
      case ContributionType.accessibilityUpdate:
        return 'Accessibility Update';
      case ContributionType.photoUpload:
        return 'Photo Upload';
      case ContributionType.confirmation:
        return 'Confirmation';
      case ContributionType.helpfulVote:
        return 'Helpful Vote';
      case ContributionType.locationAdd:
        return 'Location Added';
    }
  }

  int get pointsEarned {
    switch (this) {
      case ContributionType.review:
        return 5;
      case ContributionType.accessibilityUpdate:
        return 5;
      case ContributionType.photoUpload:
        return 10;
      case ContributionType.confirmation:
        return 3;
      case ContributionType.helpfulVote:
        return 2;
      case ContributionType.locationAdd:
        return 10;
    }
  }
}

/// A single community contribution activity.
class CommunityContribution {
  final String id;
  final ContributionType type;
  final String description;
  final int pointsEarned;
  final DateTime timestamp;
  final String? placeId;
  final String? placeName;

  const CommunityContribution({
    required this.id,
    required this.type,
    required this.description,
    required this.pointsEarned,
    required this.timestamp,
    this.placeId,
    this.placeName,
  });
}

/// User profile — works with mock user now, real auth later.
class UserProfile {
  final String id;
  final String displayName;
  final TravelMode travelMode;
  final List<AccessibilityNeed> accessibilityNeeds;
  final int communityPoints;
  final int reviewCount;
  final int accessibilityUpdates;
  final int photoCount;
  final int locationCount;
  final List<CommunityContribution> recentActivity;
  final bool onboardingComplete;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.travelMode,
    required this.accessibilityNeeds,
    this.communityPoints = 0,
    this.reviewCount = 0,
    this.accessibilityUpdates = 0,
    this.photoCount = 0,
    this.locationCount = 0,
    this.recentActivity = const [],
    this.onboardingComplete = false,
  });

  /// Check if the user's profile warrants showing wheelchair-specific score.
  bool get shouldShowWheelchairScore => accessibilityNeeds.any(
        (need) => need.isPhysicalAccessibility,
      );

  UserProfile copyWith({
    String? displayName,
    TravelMode? travelMode,
    List<AccessibilityNeed>? accessibilityNeeds,
    int? communityPoints,
    int? reviewCount,
    int? accessibilityUpdates,
    int? photoCount,
    int? locationCount,
    List<CommunityContribution>? recentActivity,
    bool? onboardingComplete,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      travelMode: travelMode ?? this.travelMode,
      accessibilityNeeds: accessibilityNeeds ?? this.accessibilityNeeds,
      communityPoints: communityPoints ?? this.communityPoints,
      reviewCount: reviewCount ?? this.reviewCount,
      accessibilityUpdates: accessibilityUpdates ?? this.accessibilityUpdates,
      photoCount: photoCount ?? this.photoCount,
      locationCount: locationCount ?? this.locationCount,
      recentActivity: recentActivity ?? this.recentActivity,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  /// Default mock user for development.
  static UserProfile mockUser() => UserProfile(
        id: 'demo-user',
        displayName: 'Demo User',
        travelMode: TravelMode.solo,
        accessibilityNeeds: [AccessibilityNeed.cannotSee],
        communityPoints: 245,
        reviewCount: 12,
        accessibilityUpdates: 8,
        photoCount: 4,
        locationCount: 1,
        recentActivity: [
          CommunityContribution(
            id: 'c1',
            type: ContributionType.review,
            description: 'Reviewed Fishka Restaurant',
            pointsEarned: 5,
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            placeName: 'Fishka Restaurant',
          ),
          CommunityContribution(
            id: 'c2',
            type: ContributionType.accessibilityUpdate,
            description: 'Added ramp information at Basilica of Bom Jesus',
            pointsEarned: 5,
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            placeName: 'Basilica of Bom Jesus',
          ),
          CommunityContribution(
            id: 'c3',
            type: ContributionType.photoUpload,
            description: 'Added accessibility photo at Miramar Beach',
            pointsEarned: 10,
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
            placeName: 'Miramar Beach',
          ),
        ],
      );
}
