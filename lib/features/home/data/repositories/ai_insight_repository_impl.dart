import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/domain/entities/ai_insight.dart';
import 'package:eunora/features/home/domain/repositories/ai_insight_repository.dart';

class AiInsightRepositoryImpl implements AiInsightRepository {
  final FirestoreService _firestoreService;

  AiInsightRepositoryImpl(this._firestoreService);

  @override
  Future<List<AiInsight>> getInsights(String uid) {
    return _firestoreService.getAiInsights(uid);
  }

  @override
  Future<void> saveInsight(String uid, AiInsight insight) {
    return _firestoreService.saveAiInsight(uid, insight);
  }
}

final aiInsightRepositoryProvider = Provider<AiInsightRepository>((ref) {
  return AiInsightRepositoryImpl(ref.read(firestoreServiceProvider));
});
