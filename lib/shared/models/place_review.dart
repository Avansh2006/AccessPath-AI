import 'accessibility_need.dart';
import 'travel_mode.dart';

/// Context about the reviewer for a particular review.
class AccessibilityContext {
  final TravelMode? travelMode;
  final List<AccessibilityNeed> accessibilityNeeds;
  final String? customDescription;

  const AccessibilityContext({
    this.travelMode,
    this.accessibilityNeeds = const [],
    this.customDescription,
  });

  String get displayLabel {
    if (accessibilityNeeds.isEmpty && travelMode == null) {
      return 'Community member';
    }
    final parts = <String>[];
    if (accessibilityNeeds.isNotEmpty) {
      parts.add(accessibilityNeeds.map((n) => n.displayName).join(', '));
    }
    if (travelMode != null) {
      parts.add(travelMode!.displayName);
    }
    return parts.join(' • ');
  }
}

/// A structured community review for a place.
class PlaceReview {
  final String id;
  final String placeId;
  final String userId;
  final String userName;

  final double overallRating;
  final double? staffInteractionRating;
  final double? communicationRating;
  final double? assistanceRating;
  final double? physicalAccessibilityRating;
  final double? facilitiesRating;

  final String comment;
  final DateTime createdAt;
  final AccessibilityContext reviewerContext;

  final int helpfulVotes;
  final bool reported;
  final List<String> photoUrls;

  const PlaceReview({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.userName,
    required this.overallRating,
    this.staffInteractionRating,
    this.communicationRating,
    this.assistanceRating,
    this.physicalAccessibilityRating,
    this.facilitiesRating,
    required this.comment,
    required this.createdAt,
    required this.reviewerContext,
    this.helpfulVotes = 0,
    this.reported = false,
    this.photoUrls = const [],
  });

  PlaceReview copyWith({
    int? helpfulVotes,
    bool? reported,
  }) {
    return PlaceReview(
      id: id,
      placeId: placeId,
      userId: userId,
      userName: userName,
      overallRating: overallRating,
      staffInteractionRating: staffInteractionRating,
      communicationRating: communicationRating,
      assistanceRating: assistanceRating,
      physicalAccessibilityRating: physicalAccessibilityRating,
      facilitiesRating: facilitiesRating,
      comment: comment,
      createdAt: createdAt,
      reviewerContext: reviewerContext,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      reported: reported ?? this.reported,
      photoUrls: photoUrls,
    );
  }
}
