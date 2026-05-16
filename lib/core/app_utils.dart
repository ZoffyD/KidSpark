/// Shared helpers used by every screen: responsive scaling for phone vs tablet
/// (`Responsive`) and the three-language string picker (`tr`).
library;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Responsive — phone vs tablet scaling.
//  Usage: `final r = Responsive(context);` then `r.dp(100)`, `r.sp(20)`,
//  `r.icon(24)`. Construct once per build.
// ─────────────────────────────────────────────────────────────────────────────

class Responsive {
  final BuildContext context;
  late final Size size;
  late final double shortSide;

  Responsive(this.context)
    : size = MediaQuery.of(context).size,
      shortSide = MediaQuery.of(context).size.shortestSide;

  /// True when shortest side >= 600 (standard tablet breakpoint).
  bool get isTablet => shortSide >= 600;

  /// Raw scale factor: ~0.85–1.0 on phones, ~1.3–1.7 on tablets.
  double get scale => (shortSide / 400).clamp(0.85, 1.7);

  /// Scaled font size (clamped tighter to avoid giant text).
  double sp(double size) => size * scale.clamp(0.85, 1.5);

  /// Scaled dimension (padding, widget sizes, etc.).
  double dp(double size) => size * scale.clamp(0.85, 1.7);

  /// Scaled icon size.
  double icon(double size) => size * scale.clamp(0.85, 1.5);
}

// ─────────────────────────────────────────────────────────────────────────────
//  tr — three-language string picker. KidSpark ships with English, Bahasa
//  Melayu, and 中文. Use this instead of building per-screen lookup maps for
//  short labels.
// ─────────────────────────────────────────────────────────────────────────────

String tr(String lang, String en, String ms, String zh) {
  switch (lang) {
    case 'zh':
      return zh;
    case 'ms':
      return ms;
    default:
      return en;
  }
}
