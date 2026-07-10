import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/widgets/app_card.dart';
import 'package:eunora/features/insights/providers/correlation_detail_provider.dart';
import 'package:eunora/features/insights/models/insight_result.dart';

class CorrelationDetailScreen extends ConsumerWidget {
  final String id;

  const CorrelationDetailScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(correlationDetailProvider(id));

    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6),
      appBar: AppBar(
        title: Text(
          'Correlation Details',
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primary),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: detailAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
            error: (err, stack) {
              debugPrint("Error loading correlation details: $err\n$stack");
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    "Details could not be loaded. Please try again.",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
            data: (detail) {
              final corr = detail.correlation;
              final events = detail.events;

              // Design aesthetics
              Color accentColor = const Color(0xFFD8C9E0);
              if (corr.direction == 'negative') {
                accentColor = const Color(0xFFA8D5BA); // soft green
              } else if (corr.direction == 'positive') {
                accentColor = const Color(0xFFE8A89B); // peachy rose
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview header card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              corr.type == InsightType.doseChange ? 'HRT IMPACT' : 'CORRELATION PATTERN',
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: corr.direction == 'negative'
                                    ? const Color(0xFF2E5E4E)
                                    : const Color(0xFF6E3E3E),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            corr.label,
                            style: GoogleFonts.notoSerif(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Methodology Section
                    Text(
                      'METHODOLOGY',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: const Color(0xFF9B8B7E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppCard(
                      child: Text(
                        "Our correlation engine identifies relationships between your logged daily triggers and symptoms. It looks for patterns where a specific trigger (such as caffeine or stress) is followed by an increase or decrease in symptom severity. The engine calculates a mathematical correlation strength based on the occurrences of these events, helping you and your physician identify potential lifestyle factors.",
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: AppTheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Event Log Table Section
                    Text(
                      'EVENT LOG HISTORY',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: const Color(0xFF9B8B7E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: events.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  "No matching log co-occurrences found yet.",
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          : Table(
                              border: const TableBorder(
                                horizontalInside: BorderSide(color: Color(0xFFF2EDEA), width: 1),
                              ),
                              columnWidths: const {
                                0: FlexColumnWidth(1.2),
                                1: FlexColumnWidth(1.8),
                                2: FlexColumnWidth(1.0),
                              },
                              children: [
                                // Table Header
                                TableRow(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF2EDEA),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                  children: [
                                    _buildTableHeaderCell('Date'),
                                    _buildTableHeaderCell('Trigger status'),
                                    _buildTableHeaderCell('Intensity'),
                                  ],
                                ),
                                // Table Rows
                                ...events.map((e) {
                                  return TableRow(
                                    children: [
                                      _buildTableCell(DateFormat('MMM dd, yyyy').format(e.date)),
                                      _buildTableCell(e.triggerValue),
                                      _buildTableCell(e.symptomIntensity),
                                    ],
                                  );
                                }),
                              ],
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF3A3A3A),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 12,
          color: const Color(0xFF3A3A3A),
        ),
      ),
    );
  }
}
