import 'package:flutter/material.dart';
import 'package:eunora/core/theme/app_theme.dart';

class PrimaryGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const PrimaryGradientButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56, // xl height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24), // xl corner radius
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
