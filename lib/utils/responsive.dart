import 'package:flutter/material.dart';

/// Lightweight responsive helper for phone vs tablet scaling.
/// Usage: `final r = Responsive(context);` then `r.sp(20)`, `r.dp(100)`.
class Responsive {
  final BuildContext context;
  late final Size size;
  late final double shortSide;

  Responsive(this.context)
      : size = MediaQuery.of(context).size,
        shortSide = MediaQuery.of(context).size.shortestSide;

  /// True when shortest side >= 600 (standard tablet breakpoint)
  bool get isTablet => shortSide >= 600;

  /// Raw scale factor: ~0.85-1.0 on phones, ~1.3-1.7 on tablets
  double get scale => (shortSide / 400).clamp(0.85, 1.7);

  /// Scaled font size (clamped slightly tighter to avoid giant text)
  double sp(double size) => size * scale.clamp(0.85, 1.5);

  /// Scaled dimension (padding, widget sizes, etc.)
  double dp(double size) => size * scale.clamp(0.85, 1.7);

  /// Scaled icon size
  double icon(double size) => size * scale.clamp(0.85, 1.5);
}
