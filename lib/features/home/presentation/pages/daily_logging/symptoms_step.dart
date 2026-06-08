import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';

class SymptomsStep extends ConsumerWidget {
  final Set<String> selectedSymptomIds;
  final ValueChanged<String> onSymptomToggled;

  const SymptomsStep({
    super.key,
    required this.selectedSymptomIds,
    required this.onSymptomToggled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(symptomsProvider);
    final library = ref.watch(symptomLibraryProvider);

    // Get symptoms currently marked as "Frequent" (even if deselected)
    final frequentSymptoms = state.frequentSymptomIds.map((id) {
      return library.firstWhere(
        (s) => s.id == id,
        orElse: () => Symptom(
          id: id,
          name: id.replaceAll('s_', '').replaceAll('_', ' '),
          iconName: 'medical_services',
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'How are you feeling right now?',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select any symptoms that have been bothering you today. We\'re here to listen.',
          style: GoogleFonts.manrope(
            fontSize: 16,
            color: const Color(0xFF1D1B1A).withOpacity(0.6),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: frequentSymptoms.length + 1,
          itemBuilder: (context, index) {
            if (index == frequentSymptoms.length) {
              // Add Custom Other Button (opens library page)
              return Bounceable(
                onTap: () => context.push('/symptom-library'),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: const Color(0xFF9B8B7E).withOpacity(0.2),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B8B7E).withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: const Color(0xFF9B8B7E).withOpacity(0.4),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Other',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF9B8B7E).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final symptom = frequentSymptoms[index];
            final symId = symptom.id;
            final isSelected = selectedSymptomIds.contains(symId);
            final symName = symptom.name;
            final iconColor = symptom.getIconColor();
            final iconBgColor = iconColor.withOpacity(0.1);

            return Bounceable(
              onTap: () => onSymptomToggled(symId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF9B8B7E) : Colors.transparent,
                    width: isSelected ? 2 : 0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
                      blurRadius: isSelected ? 15 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isSelected ? iconColor.withOpacity(0.2) : iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        symptom.getIconData(),
                        color: iconColor,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        symName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF1D1B1A)
                              : const Color(0xFF9B8B7E),
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        // Tip banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF9B8B7E).withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF9B8B7E).withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Color(0xFF9B8B7E), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '"It\'s common to experience multiple symptoms. Logging them helps us spot patterns in your journey."',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF9B8B7E),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
