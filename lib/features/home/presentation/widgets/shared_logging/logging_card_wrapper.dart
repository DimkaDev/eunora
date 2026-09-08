import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

import 'package:eunora/features/home/presentation/widgets/shared_logging/animated_logging_icon.dart';

class LoggingCardWrapper extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Widget? trailingAction;
  final dynamic triggerValue;
  final List<Widget> children;

  const LoggingCardWrapper({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.trailingAction,
    this.triggerValue,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon, Name & Optional Trailing Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    AnimatedLoggingIcon(
                      name: name,
                      icon: icon,
                      color: color,
                      backgroundColor: backgroundColor,
                      triggerValue: triggerValue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingAction != null) trailingAction!,
            ],
          ),
          ...children,
        ],
      ),
    );
  }
}
