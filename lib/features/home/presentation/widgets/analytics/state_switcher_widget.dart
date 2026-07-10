import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class StateSwitcherWidget extends StatelessWidget {
  final bool isSufficient;
  final ValueChanged<bool> onStateChanged;

  const StateSwitcherWidget({
    super.key,
    required this.isSufficient,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DASHBOARD STATE',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSufficient
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isSufficient ? 'SUFFICIENT DATA' : 'INSUFFICIENT DATA',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSufficient
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFBA1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onStateChanged(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !isSufficient ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'Insufficient (Empty)',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: !isSufficient ? FontWeight.bold : FontWeight.normal,
                          color: !isSufficient ? Colors.white : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onStateChanged(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSufficient ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'Sufficient (Active)',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: isSufficient ? FontWeight.bold : FontWeight.normal,
                          color: isSufficient ? Colors.white : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
