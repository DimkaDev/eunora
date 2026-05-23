import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class DailyTriggersCard extends StatelessWidget {
  final List<Map<String, dynamic>> loggedTriggers;
  final VoidCallback onAddTrigger;
  final VoidCallback onEditTrigger;

  const DailyTriggersCard({
    super.key,
    required this.loggedTriggers,
    required this.onAddTrigger,
    required this.onEditTrigger,
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

        final isStress = name.toLowerCase() == 'stress';

        return InkWell(
          onTap: onEditTrigger,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isStress ? const Color(0xFFFFDAD3).withOpacity(0.6) : const Color(0xFFF5F5F4),
              borderRadius: BorderRadius.circular(16),
              border: isStress
                  ? Border.all(color: const Color(0xFFFFDAD3))
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isStress ? const Color(0xFF814F45) : const Color(0xFF78716C),
                  size: 22,
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
                          color: isStress ? const Color(0xFF814F45) : const Color(0xFF4D453F),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        value,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isStress ? const Color(0xFF683A31).withOpacity(0.8) : const Color(0xFFA8A29E),
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
