import 'package:eunora/features/home/domain/entities/ai_insight.dart';

abstract class AiInsightRepository {
  Future<List<AiInsight>> getInsights(String uid);
  Future<void> saveInsight(String uid, AiInsight insight);
}
