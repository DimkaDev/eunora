import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom sheet explaining how patterns and insights are calculated in plain, clear language.
class CalculationMethodsSheet extends StatelessWidget {
  const CalculationMethodsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CalculationMethodsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0DDD5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'How Are Insights Calculated?',
                  style: GoogleFonts.notoSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D402D),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF8C7D70)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _MethodItem(
                    number: '1',
                    title: 'What is an event?',
                    body:
                        'An event is any calendar day where you logged a specific factor — such as having coffee, experiencing high stress, or exercising. Only completed daily logs participate in our calculations.',
                  ),
                  _MethodItem(
                    number: '2',
                    title: 'The analysis window',
                    body:
                        'We evaluate your logged entries over the trailing 30 days (or 90 days for longer views). Days without a log are treated as unknown rather than zero, avoiding skewed or misleading averages.',
                  ),
                  _MethodItem(
                    number: '3',
                    title: 'Personal correlation strength',
                    body:
                        'Pattern strength is measured using the Pearson correlation coefficient between factor presence and your daily symptom scores. It reflects how consistently symptoms change on days with that factor.',
                  ),
                  _MethodItem(
                    number: '4',
                    title: 'The 7-event minimum',
                    body:
                        'To protect against false positives and coincidences, a factor must occur on at least 7 separate logged days. We also require at least 3 comparison days without the factor.',
                  ),
                  _MethodItem(
                    number: '5',
                    title: '30% display threshold',
                    body:
                        'We only highlight patterns with a correlation strength of 30% or higher. Relationships below 30% are treated as inconclusive and remain hidden until clearer data emerges.',
                  ),
                  _MethodItem(
                    number: '6',
                    title: 'Exploratory insights',
                    body:
                        'These patterns are exploratory observations from your self-reported logs. They help you notice potential lifestyle connections to discuss with your healthcare provider.',
                  ),
                  _MethodItem(
                    number: '7',
                    title: 'Correlation is not causation',
                    body:
                        'Two events occurring together does not prove that one caused the other. Factors like sleep, weather, and life stress often overlap. Never adjust prescribed medications without clinical consultation.',
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodItem extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _MethodItem({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF2EFE9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0DDD5)),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D534A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D402D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: const Color(0xFF5D534A),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
