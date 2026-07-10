import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/hrt_tracker/data/hrt_quick_add_service.dart';
import 'package:eunora/features/hrt_tracker/data/hrt_drug_library.dart';

/// A tappable Quick-Add card displayed in the horizontal row above the
/// drug name search field in the Add Medication modal.
///
/// Design principles (MenoSync dignity-over-delight):
/// - No badges, no rank indicators, no "trending" labels.
/// - Silent personalization: [isFromUserHistory] affects rank order only,
///   not visual appearance.
class HrtQuickAddCard extends StatelessWidget {
  final HrtDrugOption drug;
  final VoidCallback onTap;

  const HrtQuickAddCard({
    super.key,
    required this.drug,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7E1DF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconForForms(drug.commonForms),
                color: AppTheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              drug.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A3A),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Maps the primary form type to an icon. Reuses the same iconography
  /// as the medication type tiles in AddMedicationModal.
  static IconData _iconForForms(List<String> forms) {
    final primary = forms.isNotEmpty ? forms.first : 'other';
    switch (primary) {
      case 'patch':
        return Icons.rectangle_outlined;
      case 'gel':
      case 'spray':
        return Icons.clean_hands;
      case 'tablet':
        return Icons.medication;
      default:
        return Icons.medical_services_outlined;
    }
  }
}
