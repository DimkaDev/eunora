import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Reusable transition helper for GoRouter routes to provide a high-end
/// Apple/Stripe-level transition (slight scale + slide + fade).
CustomTransitionPage<T> buildSmoothPageTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

  if (reducedMotion) {
    return NoTransitionPage<T>(
      key: state.pageKey,
      child: child,
    );
  }

  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween<Offset>(
        begin: const Offset(0.0, 0.04),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.16, 1, 0.3, 1), // easeOutExpo
        ),
      );

      final scaleTween = Tween<double>(
        begin: 0.98,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.16, 1, 0.3, 1),
        ),
      );

      final fadeTween = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
      );

      return FadeTransition(
        opacity: fadeTween,
        child: ScaleTransition(
          scale: scaleTween,
          child: SlideTransition(
            position: slideTween,
            child: child,
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
  );
}
