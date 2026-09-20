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
  /// Analyzes [activeMeds] (already added medications) and excludes them
  /// so that already added medications are removed from Quick-Add.
  ///
  /// Fills the 4 slots with the most frequently prescribed HRT medications
  /// from [kHrtDrugLibrary] (systemicEstrogen + progestogenOnly categories,
  /// [HrtDrugDefinition.isDiscontinued] == false) in prescribing-frequency order.
  ///
  /// This is a pure synchronous function — active medications are already
  /// in-memory via [medicationsProvider].
  static List<HrtDrugOption> getQuickAddDrugs(List<Medication> activeMeds) {
    final seen = <String>{};
    final result = <HrtDrugOption>[];

    bool isAlreadyAdded(HrtDrugDefinition def) {
      final defName = def.name.toLowerCase().trim();
      for (final med in activeMeds) {
        final medName = med.name.toLowerCase().trim();
        if (medName.isEmpty) continue;
        if (medName == defName) return true;
        if (medName.startsWith('$defName ') || medName.startsWith('$defName-')) return true;
        if (defName.startsWith('$medName ') || defName.startsWith('$medName-')) return true;
      }
      return false;
    }

    for (final def in kHrtDrugLibrary) {
      if (result.length >= 4) break;
      if (seen.contains(def.name) || def.isDiscontinued) continue;
      if (def.category != HrtDrugCategory.systemicEstrogen &&
          def.category != HrtDrugCategory.progestogenOnly) {
        continue;
      }
      if (isAlreadyAdded(def)) continue;

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
