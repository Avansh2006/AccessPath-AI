import 'package:access_map/shared/models/accessibility_rating.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = AccessibilityScoreCalculator();

  test('weighted score normalizes after excluding N/A', () {
    final score = calculator.calculate([
      {
        AccessibilityCriterion.stepFreeAccess: AccessibilityRating.rated(5),
        AccessibilityCriterion.lifts: const AccessibilityRating.notApplicable(),
        AccessibilityCriterion.accessibleWashrooms: AccessibilityRating.rated(
          4,
        ),
        AccessibilityCriterion.seating: AccessibilityRating.rated(3),
        AccessibilityCriterion.wayfinding: AccessibilityRating.rated(2),
      },
    ]);
    expect(score.overall, closeTo(76.25, 0.001));
    expect(score.categoryScores[AccessibilityCriterion.lifts], isNull);
  });

  test('unknown information is never verified', () {
    final score = calculator.calculate([
      {
        AccessibilityCriterion.stepFreeAccess:
            const AccessibilityRating.unknown(),
      },
    ]);
    expect(score.overall, isNull);
    expect(
      score.evidenceFor(AccessibilityCriterion.stepFreeAccess),
      RequirementEvidence.unverified,
    );
  });

  test('ratings outside 0 to 5 are rejected', () {
    expect(() => AccessibilityRating.rated(6), throwsArgumentError);
  });
}
