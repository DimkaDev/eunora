import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/hrt_tracker/data/hrt_quick_add_service.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';

/// Provides the 4 Quick-Add drug options for the Add Medication modal.
///
/// Watches [medicationsProvider] so it automatically re-ranks after any
/// [addMedication] or [removeMedication] call — no manual invalidation needed.
final hrtQuickAddProvider = Provider<List<HrtDrugOption>>((ref) {
  final medications = ref.watch(medicationsProvider).medications;
  return HrtQuickAddService.getQuickAddDrugs(medications);
});
