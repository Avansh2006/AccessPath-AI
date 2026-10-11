import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/models/accessibility_rating.dart';
import 'package:access_map/shared/models/place.dart';
import 'package:access_map/shared/models/place_category.dart';

/// Venue groups offered by the Live Accessibility Explorer filter bar.
enum ExplorerCategory {
  hospitals('Hospitals'),
  restaurants('Restaurants'),
  malls('Malls'),
  parks('Parks'),
  transport('Transport'),
  other('Other venues');

  const ExplorerCategory(this.label);

  final String label;

  bool matches(PlaceCategory category) => switch (this) {
    hospitals =>
      category == PlaceCategory.hospital || category == PlaceCategory.clinic,
    restaurants =>
      category == PlaceCategory.restaurant || category == PlaceCategory.cafe,
    malls => category == PlaceCategory.mall,
    parks => category == PlaceCategory.park,
    transport => category == PlaceCategory.transport,
    other => !ExplorerCategory.values
        .where((group) => group != ExplorerCategory.other)
        .any((group) => group.matches(category)),
  };
}

/// Search radius options around the user's (or the default) location.
enum ExplorerRadius {
  oneKm(1, 15),
  twoKm(2, 14),
  fiveKm(5, 13);

  const ExplorerRadius(this.km, this.zoom);

  final double km;
  final double zoom;

  String get label => '${km.toStringAsFixed(0)} km';
}

/// How well a place fits the user's needs, based only on community ratings.
enum Suitability {
  good('Good fit'),
  partial('Partial fit'),
  poor('Poor fit'),
  unknown('No ratings yet');

  const Suitability(this.label);

  final String label;
}

/// How much community evidence backs a [Suitability] verdict.
enum SuitabilityConfidence {
  none('No evidence'),
  low('Low confidence'),
  medium('Medium confidence'),
  high('High confidence');

  const SuitabilityConfidence(this.label);

  final String label;
}

class SuitabilityResult {
  const SuitabilityResult({
    required this.suitability,
    required this.confidence,
    required this.score,
    required this.ratedCriteria,
    required this.relevantCriteria,
    required this.reviewCount,
  });

  final Suitability suitability;
  final SuitabilityConfidence confidence;

  /// Weighted 0–100 score over the relevant criteria that have ratings.
  /// Null when no relevant criterion has been rated.
  final double? score;
  final int ratedCriteria;
  final int relevantCriteria;
  final int reviewCount;
}

/// Personalised marker suitability. Unknown data is never treated as
/// accessible: unrated criteria lower confidence instead of the score.
class SuitabilityEvaluator {
  const SuitabilityEvaluator();

  static const double goodThreshold = 70;
  static const double partialThreshold = 50;

  /// Criteria that matter for the given needs plus any essentials the user
  /// picked. Falls back to all five criteria when nothing is specific.
  Set<AccessibilityCriterion> relevantCriteria(
    Iterable<AccessibilityNeed> needs, {
    Iterable<AccessibilityCriterion> essentials = const [],
  }) {
    final criteria = <AccessibilityCriterion>{...essentials};
    for (final need in needs) {
      switch (need) {
        case AccessibilityNeed.wheelchairUser:
        case AccessibilityNeed.physicallyDisabled:
          criteria.addAll(const [
            AccessibilityCriterion.stepFreeAccess,
            AccessibilityCriterion.lifts,
            AccessibilityCriterion.accessibleWashrooms,
            AccessibilityCriterion.seating,
          ]);
        case AccessibilityNeed.cannotSee:
        case AccessibilityNeed.visuallyImpaired:
          criteria.addAll(const [
            AccessibilityCriterion.wayfinding,
            AccessibilityCriterion.stepFreeAccess,
          ]);
        case AccessibilityNeed.deaf:
        case AccessibilityNeed.cannotTalk:
        case AccessibilityNeed.cannotSpeak:
          criteria.add(AccessibilityCriterion.wayfinding);
        case AccessibilityNeed.other:
          break;
      }
    }
    return criteria.isEmpty ? AccessibilityCriterion.values.toSet() : criteria;
  }

  SuitabilityResult evaluate(
    Place place,
    Set<AccessibilityCriterion> relevant,
  ) {
    final score = place.accessibilityScore;
    final reviewCount = score.reviewCount;
    final applicable = relevant
        .where(
          (criterion) =>
              score.evidenceFor(criterion) != RequirementEvidence.notApplicable,
        )
        .toList();
    var weighted = 0.0;
    var weight = 0.0;
    var rated = 0;
    var anyUnavailable = false;
    for (final criterion in applicable) {
      final value = score.categoryScores[criterion];
      if (value == null) continue;
      rated++;
      weighted += value * criterion.weight;
      weight += criterion.weight;
      if (score.evidenceFor(criterion) == RequirementEvidence.unavailable) {
        anyUnavailable = true;
      }
    }
    if (rated == 0) {
      return SuitabilityResult(
        suitability: Suitability.unknown,
        confidence: SuitabilityConfidence.none,
        score: null,
        ratedCriteria: 0,
        relevantCriteria: applicable.length,
        reviewCount: reviewCount,
      );
    }
    final personalScore = weighted / weight;
    var suitability = personalScore >= goodThreshold
        ? Suitability.good
        : personalScore >= partialThreshold
        ? Suitability.partial
        : Suitability.poor;
    // A relevant criterion the community rated as inaccessible caps the
    // verdict, even when the average looks good.
    if (anyUnavailable && suitability == Suitability.good) {
      suitability = Suitability.partial;
    }
    final coverage = applicable.isEmpty ? 0.0 : rated / applicable.length;
    final confidence = reviewCount >= 3 && coverage >= 1
        ? SuitabilityConfidence.high
        : reviewCount >= 2 && coverage >= 0.5
        ? SuitabilityConfidence.medium
        : SuitabilityConfidence.low;
    return SuitabilityResult(
      suitability: suitability,
      confidence: confidence,
      score: personalScore,
      ratedCriteria: rated,
      relevantCriteria: applicable.length,
      reviewCount: reviewCount,
    );
  }
}

/// Applies the explorer's category and radius filters and sorts the result
/// nearest-first around [centerLatitude]/[centerLongitude].
List<Place> filterExplorerPlaces(
  Iterable<Place> places, {
  required double centerLatitude,
  required double centerLongitude,
  required ExplorerRadius radius,
  ExplorerCategory? category,
}) {
  final withDistance = <(Place, double)>[];
  for (final place in places) {
    if (category != null && !category.matches(place.category)) continue;
    final distance = place.distanceKmFrom(centerLatitude, centerLongitude);
    if (distance > radius.km) continue;
    withDistance.add((place, distance));
  }
  withDistance.sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final entry in withDistance) entry.$1];
}
