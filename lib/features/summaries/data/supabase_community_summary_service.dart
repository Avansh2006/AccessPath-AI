import 'package:access_map/features/summaries/domain/community_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCommunitySummaryService implements CommunitySummaryService {
  const SupabaseCommunitySummaryService(this.client);

  final SupabaseClient client;

  @override
  Future<CommunitySummary> forPlace(String placeId) async {
    try {
      final response = await client.functions.invoke(
        'summarize-reviews',
        body: {'placeId': placeId},
      );
      final data = response.data as Map<String, dynamic>;
      final status = switch (data['status']) {
        'available' => CommunitySummaryStatus.available,
        'insufficient_feedback' => CommunitySummaryStatus.insufficientFeedback,
        'unconfigured' => CommunitySummaryStatus.unconfigured,
        _ => CommunitySummaryStatus.error,
      };
      return CommunitySummary(
        status: status,
        message:
            data['summary'] as String? ??
            data['message'] as String? ??
            'Summary is unavailable.',
        generatedAt: DateTime.tryParse(data['generatedAt'] as String? ?? ''),
        reviewCount: data['reviewCount'] as int? ?? 0,
      );
    } catch (_) {
      return const CommunitySummary(
        status: CommunitySummaryStatus.error,
        message: 'Community summary is temporarily unavailable.',
      );
    }
  }
}
