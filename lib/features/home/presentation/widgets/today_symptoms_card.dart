import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';

class TodaySymptomsCard extends ConsumerWidget {
  final List<Map<String, String>> loggedSymptoms;
  final VoidCallback onAddSymptom;
  final VoidCallback onEditSymptom;
  final bool isLogCompleted;

  const TodaySymptomsCard({
    super.key,
    required this.loggedSymptoms,
    required this.onAddSymptom,
    required this.onEditSymptom,
    this.isLogCompleted = true,
  });

  Map<String, dynamic> _getSymptomColors(String severity) {
    Color bg;
    Color accent;
    Color barColor;
    String emoji;
    int blocks;

    switch (severity) {
      case 'Moderate':
        bg = const Color(0xFFFFF7E6);
        accent = const Color(0xFFD48806);
        barColor = const Color(0xFFFADB14);
        emoji = '😐';
        blocks = 2;
        break;
      case 'Severe':
        bg = const Color(0xFFFFF1F0);
        accent = const Color(0xFFCF1322);
        barColor = const Color(0xFFFF4D4F);
        emoji = '😟';
        blocks = 3;
        break;
      case 'Mild':
      default:
        bg = const Color(0xFFF6FFED);
        accent = const Color(0xFF389E0D);
        barColor = const Color(0xFF73D13D);
        emoji = '😊';
        blocks = 1;
        break;
    }

    return {
      'bg': bg,
      'accent': accent,
      'barColor': barColor,
      'emoji': emoji,
      'blocks': blocks,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEmpty = loggedSymptoms.isEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.show_chart,
                    color: Color(0xFF817266),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Symptoms",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (!isEmpty && isLogCompleted)
                IconButton(
                  onPressed: onEditSymptom,
                  icon: const Icon(Icons.edit_note),
                  color: const Color(0xFFA8A29E),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (isEmpty)
            _buildEmptyState(context)
          else
            _buildGridState(context, ref),
        ],
      ),
    );
  }

  // Dashed Empty State Box
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE7E1DF),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hotel_class,
            color: Color(0xFFD6D3D1),
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            "No logs yet",
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF78716C),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isLogCompleted
                ? "Track how you're feeling today"
                : "Complete daily logging first to add symptoms",
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: const Color(0xFFA8A29E),
            ),
          ),
          if (isLogCompleted) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAddSymptom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                foregroundColor: AppTheme.primary,
                shadowColor: Colors.transparent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Add Symptom',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Grid State with trailing "+ Add New" dashed button
  Widget _buildGridState(BuildContext context, WidgetRef ref) {
    final int itemsCount = loggedSymptoms.length + (isLogCompleted ? 1 : 0);
    final library = ref.watch(symptomLibraryProvider);

    // Find symptom details by name
    Symptom findSymptomByName(String name) {
      final nameLower = name.toLowerCase();
      return library.firstWhere(
        (s) => s.name.toLowerCase() == nameLower,
        orElse: () => Symptom(
          id: 's_${nameLower.replaceAll(' ', '_')}',
          name: name,
          iconName: 'medical_services',
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.3,
      ),
      itemCount: itemsCount,
      itemBuilder: (context, index) {
        if (index == loggedSymptoms.length) {
          // Render trailing "+ Add New" button
          return InkWell(
            onTap: onAddSymptom,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD0C4BC).withValues(alpha: 0.6),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add,
                    color: Color(0xFFA8A29E),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Add New',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFA8A29E),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final symptomMapEntry = loggedSymptoms[index];
        final String name = symptomMapEntry['name'] ?? '';
        final String severity = symptomMapEntry['severity'] ?? 'Mild';

        final symptom = findSymptomByName(name);
        final symIcon = symptom.getIconData();

        final colors = _getSymptomColors(severity);
        final bg = colors['bg']!;
        final accent = colors['accent']!;
        final barColor = colors['barColor']!;
        final emoji = colors['emoji']!;
        final blocks = colors['blocks']!;

        return InkWell(
          onTap: onEditSymptom,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    symIcon,
                    color: accent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2A2421),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Text(
                            '$emoji $severity',
                            style: GoogleFonts.manrope(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            children: List.generate(3, (index) {
                              final active = index < blocks;
                              return Container(
                                width: 3.5,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                decoration: BoxDecoration(
                                  color: active ? barColor : barColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
