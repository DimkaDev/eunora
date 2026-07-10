import 'package:eunora/features/hrt_tracker/data/hrt_drug_library.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';

/// Plain DTO representing a drug option in the Quick-Add row.
class HrtDrugOption {
  final String name;
  final HrtDrugCategory category;
  final List<String> commonForms;
  final bool isCombinedProduct;
  final HrtMarket market;

  /// true = ranked by this user's own logged data, not the static library.
  final bool isFromUserHistory;

  const HrtDrugOption({
    required this.name,
    required this.category,
    required this.commonForms,
    required this.isCombinedProduct,
    required this.market,
    this.isFromUserHistory = false,
  });
}

class HrtQuickAddService {
  /// Returns up to 4 [HrtDrugOption] for the Quick-Add row.
  ///
  /// Cold start (no active HRT history for this user): returns the static
  /// frequency-ranked library — systemicEstrogen + progestogenOnly categories
  /// only, [HrtDrugDefinition.isDiscontinued] == false.
  ///
  /// Warm start: re-ranks by the user's own active medications first, then
  /// pads remaining slots from the static list.
  ///
  /// This is a pure synchronous function — active medications are already
  /// in-memory via [medicationsProvider].
  static List<HrtDrugOption> getQuickAddDrugs(List<Medication> activeMeds) {
    final seen = <String>{};
    final result = <HrtDrugOption>[];

    // --- Warm start: promote user's own active meds ---
    for (final med in activeMeds) {
      if (result.length >= 4) break;
      final def = kHrtDrugLibrary
          .where((d) => d.name.toLowerCase() == med.name.toLowerCase())
          .firstOrNull;
      if (def == null || seen.contains(def.name)) continue;
      result.add(HrtDrugOption(
        name: def.name,
        category: def.category,
        commonForms: def.commonForms,
        isCombinedProduct: def.isCombinedProduct,
        market: def.market,
        isFromUserHistory: true,
      ));
      seen.add(def.name);
    }

    // --- Cold-start pad: fill remaining slots from static library ---
    for (final def in kHrtDrugLibrary) {
      if (result.length >= 4) break;
      if (seen.contains(def.name) || def.isDiscontinued) continue;
      if (def.category != HrtDrugCategory.systemicEstrogen &&
          def.category != HrtDrugCategory.progestogenOnly) {
        continue;
      }
      result.add(HrtDrugOption(
        name: def.name,
        category: def.category,
        commonForms: def.commonForms,
        isCombinedProduct: def.isCombinedProduct,
        market: def.market,
        isFromUserHistory: false,
      ));
      seen.add(def.name);
    }

    return result;
  }

  /// Returns all drug names in [kHrtDrugLibrary] matching [query] for
  /// the full-text autocomplete search field in the Add Medication modal.
  static List<HrtDrugDefinition> search(String query) {
    if (query.isEmpty) return kHrtDrugLibrary;
    final q = query.toLowerCase();
    return kHrtDrugLibrary
        .where((d) => d.name.toLowerCase().contains(q))
        .toList();
  }

  /// Returns the [HrtDrugDefinition] for [name] or null if not found.
  static HrtDrugDefinition? findByName(String name) {
    return kHrtDrugLibrary
        .where((d) => d.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;
  }
}
