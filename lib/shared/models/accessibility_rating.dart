enum AccessibilityCriterion {
  stepFreeAccess('Step-free access', 0.30),
  lifts('Lifts', 0.20),
  accessibleWashrooms('Accessible washrooms', 0.20),
  seating('Seating', 0.15),
  wayfinding('Wayfinding', 0.15);

  const AccessibilityCriterion(this.label, this.weight);

  final String label;
  final double weight;
}

enum AccessibilityRatingStatus {
  rated,
  unknown,
  notApplicable;

  String get label => switch (this) {
    rated => 'Rated',
    unknown => 'Unknown',
    notApplicable => 'Not applicable',
  };
}

class AccessibilityRating {
  const AccessibilityRating._({required this.status, this.value});

  factory AccessibilityRating.rated(double value) {
    if (value < 0 || value > 5) {
      throw ArgumentError.value(value, 'value', 'must be between 0 and 5');
    }
    return AccessibilityRating._(
      status: AccessibilityRatingStatus.rated,
      value: value,
    );
  }

  const AccessibilityRating.unknown()
    : this._(status: AccessibilityRatingStatus.unknown);

  const AccessibilityRating.notApplicable()
    : this._(status: AccessibilityRatingStatus.notApplicable);

  final AccessibilityRatingStatus status;
  final double? value;

  Map<String, dynamic> toJson() => {'status': status.name, 'value': value};

  factory AccessibilityRating.fromJson(Map<String, dynamic> json) {
    final status = AccessibilityRatingStatus.values.firstWhere(
      (item) => item.name == json['status'],
      orElse: () => AccessibilityRatingStatus.unknown,
    );
    if (status == AccessibilityRatingStatus.rated && json['value'] is num) {
      return AccessibilityRating.rated(
        (json['value'] as num).toDouble().clamp(0, 5),
      );
    }
    return status == AccessibilityRatingStatus.notApplicable
        ? const AccessibilityRating.notApplicable()
        : const AccessibilityRating.unknown();
  }
}

enum RequirementEvidence { verified, unavailable, unverified, notApplicable }

class AccessibilityScore {
  const AccessibilityScore({
    required this.overall,
    required this.categoryScores,
    required this.categoryEvidence,
    required this.reviewCount,
  });

  final double? overall;
  final Map<AccessibilityCriterion, double?> categoryScores;
  final Map<AccessibilityCriterion, RequirementEvidence> categoryEvidence;
  final int reviewCount;

  bool get hasEvidence => overall != null;

  RequirementEvidence evidenceFor(AccessibilityCriterion criterion) =>
      categoryEvidence[criterion] ?? RequirementEvidence.unverified;
}

class AccessibilityScoreCalculator {
  const AccessibilityScoreCalculator();

  AccessibilityScore calculate(
    Iterable<Map<AccessibilityCriterion, AccessibilityRating>> reviews,
  ) {
    final submissions = reviews.toList();
    final categoryScores = <AccessibilityCriterion, double?>{};
    final evidence = <AccessibilityCriterion, RequirementEvidence>{};

    for (final criterion in AccessibilityCriterion.values) {
      final entries = submissions
          .map((review) => review[criterion])
          .whereType<AccessibilityRating>()
          .toList();
      final values = entries
          .where((rating) => rating.status == AccessibilityRatingStatus.rated)
          .map((rating) => rating.value!)
          .toList();
      if (values.isNotEmpty) {
        final score = values.reduce((a, b) => a + b) / values.length * 20;
        categoryScores[criterion] = score;
        evidence[criterion] = score >= 60
            ? RequirementEvidence.verified
            : RequirementEvidence.unavailable;
      } else {
        categoryScores[criterion] = null;
        evidence[criterion] =
            entries.isNotEmpty &&
                entries.every(
                  (rating) =>
                      rating.status == AccessibilityRatingStatus.notApplicable,
                )
            ? RequirementEvidence.notApplicable
            : RequirementEvidence.unverified;
      }
    }

    var weightedTotal = 0.0;
    var includedWeight = 0.0;
    for (final criterion in AccessibilityCriterion.values) {
      final score = categoryScores[criterion];
      if (score != null) {
        weightedTotal += score * criterion.weight;
        includedWeight += criterion.weight;
      }
    }
    return AccessibilityScore(
      overall: includedWeight == 0 ? null : weightedTotal / includedWeight,
      categoryScores: categoryScores,
      categoryEvidence: evidence,
      reviewCount: submissions.length,
    );
  }
}
