enum CommunitySummaryStatus {
  available,
  insufficientFeedback,
  unconfigured,
  error,
}

class CommunitySummary {
  const CommunitySummary({
    required this.status,
    required this.message,
    this.generatedAt,
    this.reviewCount = 0,
  });

  final CommunitySummaryStatus status;
  final String message;
  final DateTime? generatedAt;
  final int reviewCount;
}

abstract class CommunitySummaryService {
  Future<CommunitySummary> forPlace(String placeId);
}

class UnconfiguredCommunitySummaryService implements CommunitySummaryService {
  const UnconfiguredCommunitySummaryService();

  @override
  Future<CommunitySummary> forPlace(String placeId) async =>
      const CommunitySummary(
        status: CommunitySummaryStatus.unconfigured,
        message: 'AI summaries are not configured for this build.',
      );
}
