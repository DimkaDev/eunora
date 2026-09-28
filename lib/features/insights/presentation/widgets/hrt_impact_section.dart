import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../analysis/domain/models/hrt_change_result.dart';
import 'hrt_change_detail_sheet.dart';

/// Section rendering up to 5 HRT regimen-change groups, newest first.
/// Completely omitted if HRT is not set up.
/// Each card features: headline, status badge/message, overlapping note, adherence line,
/// and approved HRT Before/After disclaimer visibly on the card.
class HrtImpactSection extends StatelessWidget {
  final List<HrtRegimenGroup> groups;
  final bool isHrtSetUp;
  final void Function(HrtRegimenGroup)? onGroupTap;

  const HrtImpactSection({
    super.key,
    required this.groups,
    this.isHrtSetUp = true,
    this.onGroupTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isHrtSetUp) return const SizedBox.shrink();

    final displayGroups = groups.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HRT REGIMEN IMPACT',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: const Color(0xFF8C7D70),
              ),
            ),
            if (displayGroups.isNotEmpty)
              Text(
                'Before & After (14 days)',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: const Color(0xFF8C7D70),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (displayGroups.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBE6DF)),
            ),
            child: Text(
              'No regimen changes recorded yet. When your HRT dosage or schedule adjusts, before and after symptom comparisons will appear here.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: const Color(0xFF67594E),
                height: 1.4,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayGroups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final group = displayGroups[index];
              return _buildGroupCard(context, group);
            },
          ),
      ],
    );
  }

  Widget _buildGroupCard(BuildContext context, HrtRegimenGroup group) {
    final headline = group.headlineText ?? group.summaryTitle;

    return InkWell(
      onTap: () {
        if (onGroupTap != null) {
          onGroupTap!(group);
        } else {
          HrtChangeDetailSheet.show(context, group: group);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBE6DF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Headline + Status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    headline,
                    style: GoogleFonts.notoSerif(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D402D),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(group),
              ],
            ),
            const SizedBox(height: 8),

            // Status message / countdown
            if (group.status == HrtChangeStatus.pending) ...[
              Text(
                'Day ${group.daysSinceChange} of 14 since regimen changed · Comparison ready in ${group.daysToGo ?? (14 - group.daysSinceChange)} days.',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5D534A),
                ),
              ),
            ] else ...[
              Text(
                group.statusMessage,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF67594E),
                ),
              ),
            ],

            // Overlapping note(s)
            if (group.overlappingNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF6EE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: group.overlappingNotes.map((note) {
                    return Text(
                      'Note: $note',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: const Color(0xFF8A5A2B),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Adherence line
            if (group.adherence != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: Color(0xFF4A7C59),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      group.adherence!.adherenceText,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4A7C59),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Before & After details',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D402D),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Color(0xFF2D402D),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFF0ECE6)),
            const SizedBox(height: 8),

            // Approved HRT Before/After disclaimer
            Text(
              group.disclaimer,
              style: GoogleFonts.manrope(
                fontSize: 10,
                color: const Color(0xFF8C7D70),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(HrtRegimenGroup group) {
    Color bg;
    Color fg;
    String label;

    switch (group.status) {
      case HrtChangeStatus.ready:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = 'READY';
        break;
      case HrtChangeStatus.pending:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        label = 'PENDING';
        break;
      case HrtChangeStatus.notEnoughBaseline:
      case HrtChangeStatus.notEnoughFollowUp:
        bg = const Color(0xFFF2EFE9);
        fg = const Color(0xFF67594E);
        label = 'INSUFFICIENT DATA';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: fg,
        ),
      ),
    );
  }
}
