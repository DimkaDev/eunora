import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Subtle slide + fade transition.
/// Entering page slides in slightly (8% offset) from the right with a smooth fade,
/// providing a polished, high-performance page transition.
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
    opaque: true,
    barrierColor: null,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween<Offset>(
        begin: const Offset(0.08, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.16, 1, 0.3, 1),
        reverseCurve: const Cubic(0.16, 1, 0.3, 1),
      ));

      final fadeTween = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      );

      return SlideTransition(
        position: slideTween,
        child: FadeTransition(opacity: fadeTween, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
  );
}
