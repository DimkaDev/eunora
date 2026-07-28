import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class DailyTriggersCard extends StatelessWidget {
  final List<Map<String, dynamic>> loggedTriggers;
  final VoidCallback onAddTrigger;
  final VoidCallback onEditTrigger;
  final bool isLogCompleted;

  const DailyTriggersCard({
    super.key,
    required this.loggedTriggers,
    required this.onAddTrigger,
    required this.onEditTrigger,
    this.isLogCompleted = true,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = loggedTriggers.isEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                    Icons.bolt,
                    color: Color(0xFF817266),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Daily Triggers",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    "${loggedTriggers.length} LOGGED",
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: const Color(0xFFA8A29E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onEditTrigger,
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
            ],
          ),
          const SizedBox(height: 16),

          if (isEmpty)
            _buildEmptyState(context)
          else
            _buildGridState(context),
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
            Icons.local_cafe,
            color: Color(0xFFD6D3D1),
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            "No triggers logged",
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF78716C),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Keep track of habits and events",
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: const Color(0xFFA8A29E),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAddTrigger,
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
              'Add Trigger',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getTriggerColors(String name, String value) {
    Color bg;
    Color accent;

    final String nameLower = name.toLowerCase();
    final String valLower = value.toLowerCase();

    if (nameLower == 'stress') {
      if (valLower.contains('calm')) {
        bg = const Color(0xFFF6FFED);
        accent = const Color(0xFF389E0D);
      } else if (valLower.contains('high') || valLower.contains('severe')) {
        bg = const Color(0xFFFFF1F0);
        accent = const Color(0xFFCF1322);
      } else {
        bg = const Color(0xFFFFF7E6);
        accent = const Color(0xFFD48806);
      }
    } else if (nameLower == 'caffeine') {
      bg = const Color(0xFFFDF6F0);
      accent = const Color(0xFF8E6F5E);
    } else if (nameLower == 'alcohol') {
      bg = const Color(0xFFFFF1F0);
      accent = const Color(0xFFCF1322);
    } else if (nameLower == 'sugar') {
      bg = const Color(0xFFF9F0FF);
      accent = const Color(0xFF722ED1);
    } else if (nameLower == 'lack of sleep' || nameLower == 'poor sleep') {
      bg = const Color(0xFFF0F5FF);
      accent = const Color(0xFF2F54EB);
    } else if (nameLower == 'spicy food') {
      bg = const Color(0xFFFFF2E8);
      accent = const Color(0xFFD4380D);
    } else if (nameLower == 'exercise') {
      bg = const Color(0xFFE6FFFB);
      accent = const Color(0xFF08979C);
    } else if (nameLower == 'weather') {
      bg = const Color(0xFFE6F7FF);
      accent = const Color(0xFF096DD9);
    } else {
      bg = const Color(0xFFF5F5F4);
      accent = const Color(0xFF78716C);
    }

    return {'bg': bg, 'accent': accent};
  }

  // Grid State with trailing "+ Add New" dashed button
  Widget _buildGridState(BuildContext context) {
    final int itemsCount = loggedTriggers.length + 1; // Logged triggers + trailing add button

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
        if (index == loggedTriggers.length) {
          // Render trailing "+ Add New" button
          return InkWell(
            onTap: onAddTrigger,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD0C4BC).withOpacity(0.6),
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

        final item = loggedTriggers[index];
        final String name = item['name'] ?? '';
        final String value = item['value'] ?? '';
        final IconData icon = item['icon'] ?? Icons.bolt;

        final colors = _getTriggerColors(name, value);
        final bg = colors['bg']!;
        final accent = colors['accent']!;

        return InkWell(
          onTap: onEditTrigger,
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
                    icon,
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
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2A2421), // Charcoal for best readability
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        value,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
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
