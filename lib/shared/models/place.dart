import 'package:flutter/material.dart';

import 'accessibility_feature.dart';
import 'accessibility_need.dart';
import 'place_category.dart';
import 'place_review.dart';
import 'travel_mode.dart';
import 'dart:math' as math;

/// Where a place came from. Demo/seed places keep the app populated for
/// presentations; community places carry real contributor metadata.
enum PlaceSource {
  demo,
  community,
  official;

  String get label {
    switch (this) {
      case PlaceSource.demo:
        return 'Demo data';
      case PlaceSource.community:
        return 'Community Added';
      case PlaceSource.official:
        return 'Official';
    }
  }
}

/// A community-uploaded photo of an accessibility feature at a place.
class PlacePhoto {
  final String id;
  final String url;
  final String? caption;

  /// e.g. entrance, ramp, restroom, parking, signage.
  final String? accessibilityCategory;
  final String uploadedBy;
  final DateTime uploadedAt;

  const PlacePhoto({
    required this.id,
    required this.url,
    this.caption,
    this.accessibilityCategory,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'caption': caption,
        'accessibilityCategory': accessibilityCategory,
        'uploadedBy': uploadedBy,
        'uploadedAt': uploadedAt.toIso8601String(),
      };

  factory PlacePhoto.fromJson(Map<String, dynamic> json) => PlacePhoto(
        id: json['id'] as String,
        url: json['url'] as String,
        caption: json['caption'] as String?,
        accessibilityCategory: json['accessibilityCategory'] as String?,
        uploadedBy: json['uploadedBy'] as String? ?? 'Community member',
        uploadedAt:
            DateTime.tryParse(json['uploadedAt'] as String? ?? '') ??
                DateTime.now(),
      );
}

/// A place with accessibility data, scores, features, and reviews.
class Place {
  final String id;
  final String name;
  final PlaceCategory category;
  final String address;
  final String? phone;
  final String? website;

  /// Real Google Maps link for this venue (when known). Used by the
  /// directions action so users land on the actual place.
  final String? directionsUrl;
  final String description;

  final double latitude;
  final double longitude;

  // Scores out of 10
  final double friendlyScore;
  final double wheelchairScore;
  final double visualAccessibilityScore;
  final double hearingAccessibilityScore;
  final double communicationScore;

  final List<AccessibilityFeature> accessibilityFeatures;
  final List<PlaceReview> reviews;
  final List<String> imageUrls;
  final List<PlacePhoto> photos;

  // Score metadata
  final int totalReviews;
  final int communityConfirmations;
  final DateTime? lastVerified;

  // Community attribution
  final PlaceSource source;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? lastCommunityUpdate;

  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    this.phone,
    this.website,
    this.directionsUrl,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.friendlyScore,
    required this.wheelchairScore,
    required this.visualAccessibilityScore,
    required this.hearingAccessibilityScore,
    required this.communicationScore,
    required this.accessibilityFeatures,
    required this.reviews,
    this.imageUrls = const [],
    this.photos = const [],
    this.totalReviews = 0,
    this.communityConfirmations = 0,
    this.lastVerified,
    this.source = PlaceSource.demo,
    this.createdBy,
    this.createdAt,
    this.lastCommunityUpdate,
  });

  /// True when the place has not yet gathered enough community evidence for
  /// trustworthy scores (community submissions start here).
  bool get isNewCommunityPlace =>
      source == PlaceSource.community && totalReviews == 0;

  /// Features that are confirmed available.
  List<AccessibilityFeature> get availableFeatures => accessibilityFeatures
      .where((f) => f.status == FeatureStatus.available)
      .toList();

  /// Features that are confirmed unavailable.
  List<AccessibilityFeature> get unavailableFeatures => accessibilityFeatures
      .where((f) => f.status == FeatureStatus.unavailable)
      .toList();

  /// Features with unknown status.
  List<AccessibilityFeature> get unknownFeatures => accessibilityFeatures
      .where((f) => f.status == FeatureStatus.unknown)
      .toList();

  /// Distance in kilometres from the given coordinates.
  double distanceKmFrom(double lat, double lng) {
    const r = 6371.0; // Earth radius in km.
    final dLat = _degToRad(latitude - lat);
    final dLng = _degToRad(longitude - lng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat)) *
            math.cos(_degToRad(latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  Place copyWith({
    String? name,
    PlaceCategory? category,
    String? address,
    String? phone,
    String? website,
    String? directionsUrl,
    String? description,
    double? latitude,
    double? longitude,
    double? friendlyScore,
    double? wheelchairScore,
    double? visualAccessibilityScore,
    double? hearingAccessibilityScore,
    double? communicationScore,
    List<AccessibilityFeature>? accessibilityFeatures,
    List<PlaceReview>? reviews,
    List<PlacePhoto>? photos,
    int? totalReviews,
    int? communityConfirmations,
    DateTime? lastVerified,
    PlaceSource? source,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastCommunityUpdate,
  }) {
    return Place(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      directionsUrl: directionsUrl ?? this.directionsUrl,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      friendlyScore: friendlyScore ?? this.friendlyScore,
      wheelchairScore: wheelchairScore ?? this.wheelchairScore,
      visualAccessibilityScore:
          visualAccessibilityScore ?? this.visualAccessibilityScore,
      hearingAccessibilityScore:
          hearingAccessibilityScore ?? this.hearingAccessibilityScore,
      communicationScore: communicationScore ?? this.communicationScore,
      accessibilityFeatures:
          accessibilityFeatures ?? this.accessibilityFeatures,
      reviews: reviews ?? this.reviews,
      photos: photos ?? this.photos,
      imageUrls: imageUrls,
      totalReviews: totalReviews ?? this.totalReviews,
      communityConfirmations: communityConfirmations ?? this.communityConfirmations,
      lastVerified: lastVerified ?? this.lastVerified,
      source: source ?? this.source,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastCommunityUpdate: lastCommunityUpdate ?? this.lastCommunityUpdate,
    );
  }

  // ---------------------------------------------------------------------------
  // JSON serialization — used by the local persistence layer.
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'address': address,
        'phone': phone,
        'website': website,
        'directionsUrl': directionsUrl,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'friendlyScore': friendlyScore,
        'wheelchairScore': wheelchairScore,
        'visualAccessibilityScore': visualAccessibilityScore,
        'hearingAccessibilityScore': hearingAccessibilityScore,
        'communicationScore': communicationScore,
        'accessibilityFeatures':
            accessibilityFeatures.map((f) => _featureToJson(f)).toList(),
        'reviews': reviews.map((r) => reviewToJson(r)).toList(),
        'photos': photos.map((p) => p.toJson()).toList(),
        'totalReviews': totalReviews,
        'communityConfirmations': communityConfirmations,
        'lastVerified': lastVerified?.toIso8601String(),
        'source': source.name,
        'createdBy': createdBy,
        'createdAt': createdAt?.toIso8601String(),
        'lastCommunityUpdate': lastCommunityUpdate?.toIso8601String(),
      };

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as String,
        name: json['name'] as String,
        category:
            PlaceCategory.values.firstWhere((c) => c.name == json['category']),
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String?,
        website: json['website'] as String?,
        directionsUrl: json['directionsUrl'] as String?,
        description: json['description'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        friendlyScore: (json['friendlyScore'] as num).toDouble(),
        wheelchairScore: (json['wheelchairScore'] as num).toDouble(),
        visualAccessibilityScore:
            (json['visualAccessibilityScore'] as num).toDouble(),
        hearingAccessibilityScore:
            (json['hearingAccessibilityScore'] as num).toDouble(),
        communicationScore: (json['communicationScore'] as num).toDouble(),
        accessibilityFeatures: (json['accessibilityFeatures'] as List<dynamic>?)
                ?.map((f) => featureFromJson(f as Map<String, dynamic>))
                .toList() ??
            const [],
        reviews: (json['reviews'] as List<dynamic>?)
                ?.map((r) => reviewFromJson(r as Map<String, dynamic>))
                .toList() ??
            const [],
        photos: (json['photos'] as List<dynamic>?)
                ?.map((p) => PlacePhoto.fromJson(p as Map<String, dynamic>))
                .toList() ??
            const [],
        totalReviews: json['totalReviews'] as int? ?? 0,
        communityConfirmations: json['communityConfirmations'] as int? ?? 0,
        lastVerified: DateTime.tryParse(json['lastVerified'] as String? ?? ''),
        source: PlaceSource.values
            .firstWhere((s) => s.name == json['source']),
        createdBy: json['createdBy'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        lastCommunityUpdate:
            DateTime.tryParse(json['lastCommunityUpdate'] as String? ?? ''),
      );

  static Map<String, dynamic> _featureToJson(AccessibilityFeature f) => {
        'id': f.id,
        'name': f.name,
        'iconCodePoint': f.icon.codePoint,
        'category': f.category.name,
        'status': f.status.name,
        'confirmationCount': f.confirmationCount,
        'lastConfirmed': f.lastConfirmed?.toIso8601String(),
      };

  static AccessibilityFeature featureFromJson(Map<String, dynamic> json) {
    final category = AccessibilityCategory.values
        .firstWhere((c) => c.name == json['category']);
    final codePoint = json['iconCodePoint'] as int? ?? Icons.accessible.codePoint;
    return AccessibilityFeature(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: _iconForCodePoint(codePoint, category),
      category: category,
      status:
          FeatureStatus.values.firstWhere((s) => s.name == json['status']),
      confirmationCount: json['confirmationCount'] as int? ?? 0,
      lastConfirmed:
          DateTime.tryParse(json['lastConfirmed'] as String? ?? ''),
    );
  }

  /// Maps persisted code points back to Material icons, falling back to the
  /// category icon if the font version ever changes code points.
  static IconData _iconForCodePoint(int codePoint, AccessibilityCategory category) {
    for (final icon in _knownFeatureIcons.values) {
      if (icon.codePoint == codePoint) return icon;
    }
    return category.icon;
  }

  static const Map<String, IconData> _knownFeatureIcons = {
    'ramp': Icons.accessible,
    'door': Icons.door_front_door,
    'elevator': Icons.elevator,
    'wc': Icons.wc,
    'parking': Icons.local_parking,
    'staff': Icons.support_agent,
    'signage': Icons.signpost,
    'tactile': Icons.touch_app,
    'braille': Icons.menu_book,
    'audio': Icons.headphones,
    'tv': Icons.tv,
    'write': Icons.edit_note,
    'sign_language': Icons.sign_language,
    'chat': Icons.chat,
    'walk': Icons.directions_walk,
    'wide': Icons.door_sliding,
    'counter': Icons.vertical_align_bottom,
    'seating': Icons.event_seat,
    'contrast': Icons.contrast,
    'emergency': Icons.emergency,
    'digital': Icons.devices,
    'handrails': Icons.ramp_left,
  };

  // Review JSON (shared with repository persistence).

  static Map<String, dynamic> reviewToJson(PlaceReview r) => {
        'id': r.id,
        'placeId': r.placeId,
        'userId': r.userId,
        'userName': r.userName,
        'overallRating': r.overallRating,
        'staffInteractionRating': r.staffInteractionRating,
        'communicationRating': r.communicationRating,
        'assistanceRating': r.assistanceRating,
        'physicalAccessibilityRating': r.physicalAccessibilityRating,
        'facilitiesRating': r.facilitiesRating,
        'comment': r.comment,
        'createdAt': r.createdAt.toIso8601String(),
        'travelMode': r.reviewerContext.travelMode?.name,
        'needs': r.reviewerContext.accessibilityNeeds.map((n) => n.name).toList(),
        'helpfulVotes': r.helpfulVotes,
        'reported': r.reported,
      };

  static PlaceReview reviewFromJson(Map<String, dynamic> json) {
    final travelMode = json['travelMode'] as String?;
    final needs = (json['needs'] as List<dynamic>? ?? [])
        .map((n) => AccessibilityNeed.values
            .firstWhere((need) => need.name == n))
        .toList();
    return PlaceReview(
      id: json['id'] as String,
      placeId: json['placeId'] as String,
      userId: json['userId'] as String? ?? 'unknown',
      userName: json['userName'] as String? ?? 'Community member',
      overallRating: (json['overallRating'] as num).toDouble(),
      staffInteractionRating: (json['staffInteractionRating'] as num?)?.toDouble(),
      communicationRating: (json['communicationRating'] as num?)?.toDouble(),
      assistanceRating: (json['assistanceRating'] as num?)?.toDouble(),
      physicalAccessibilityRating:
          (json['physicalAccessibilityRating'] as num?)?.toDouble(),
      facilitiesRating: (json['facilitiesRating'] as num?)?.toDouble(),
      comment: json['comment'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
              DateTime.now(),
      reviewerContext: AccessibilityContext(
        travelMode: travelMode == null
            ? null
            : TravelMode.values.firstWhere((t) => t.name == travelMode),
        accessibilityNeeds: needs,
      ),
      helpfulVotes: json['helpfulVotes'] as int? ?? 0,
      reported: json['reported'] as bool? ?? false,
    );
  }
}
