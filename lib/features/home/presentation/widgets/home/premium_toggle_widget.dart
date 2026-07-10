import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class PremiumToggleWidget extends StatelessWidget {
  final bool isPremium;
  final VoidCallback onTap;

  const PremiumToggleWidget({
    super.key,
    required this.isPremium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isPremium
                ? const Color(0xFF1D1B1A).withValues(alpha: 0.88)
                : AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isPremium
                  ? const Color(0xFFD4AF37)
                  : AppTheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPremium ? Icons.star_rounded : Icons.star_border_rounded,
                size: 14,
                color: isPremium
                    ? const Color(0xFFD4AF37)
                    : AppTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                isPremium
                    ? '★ Premium ON  —  tap to disable'
                    : '☆ Premium OFF  —  tap to enable',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPremium
                      ? const Color(0xFFD4AF37)
                      : AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
