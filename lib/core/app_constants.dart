/// All static "knobs" for KidSpark: persistence keys, the GameType enum,
/// the colour palette, and corner radii. 
/// magic value the app uses.
library;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PrefsKeys — every SharedPreferences / Firestore field name in one place
// ─────────────────────────────────────────────────────────────────────────────

class PrefsKeys {
  PrefsKeys._();

  // Settings
  static const language = 'kidspark_language';
  static const music = 'kidspark_music';
  static const sfx = 'kidspark_sfx';

  // Highest unlocked level per game
  static const wordUnlocked = 'kidspark_word_unlocked';
  static const emotionalUnlocked = 'kidspark_emotional_unlocked';
  static const problemUnlocked = 'kidspark_problem_unlocked';

  /// Returns the unlocked-level key for a given internal game type code.
  static String unlockedFor(String gameType) => 'kidspark_${gameType}_unlocked';

  /// Returns the per-level stars key for a given game and level.
  static String starsFor(String gameType, int level) =>
      'kidspark_${gameType}_stars_$level';

  /// Cache-readiness flag, versioned so bumping invalidates old caches.
  static String ttsCacheReady(int version) =>
      'kidspark_tts_cache_ready_v$version';
}

// ─────────────────────────────────────────────────────────────────────────────
//  GameType — the three mini-games. `code` matches the historical string
//  identifier used in prefs / Firestore keys so persisted progress is safe.
// ─────────────────────────────────────────────────────────────────────────────

enum GameType {
  word('word'),
  emotional('emotional'),
  problem('problem');

  final String code;
  const GameType(this.code);

  static GameType fromCode(String code) => GameType.values.firstWhere(
    (g) => g.code == code,
    orElse: () => GameType.word,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  AppColors — shared palette. Defining these once keeps the UI coherent
//  across screens and makes retheming a one-file change.
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Backgrounds
  static const splashBg = Color(0xFFF0FBF5);
  static const dashboardBg = Color(0xFFF8FAFC);
  static const wordBg = Color(0xFFFDF2F8);
  static const emotionalBg = Color(0xFFF0F9FF);
  static const puzzleBg = Color(0xFFECFDF5);

  // Accents per game
  static const wordAccent = Colors.pinkAccent;
  static const emotionalAccent = Colors.blueAccent;
  static const puzzleAccent = Colors.greenAccent;
  static const settingsAccent = Colors.purpleAccent;

  // Text
  static const heading = Color(0xFF2D3142);
  static const chip = Color(0xFF3D3D3D);
}

// ─────────────────────────────────────────────────────────────────────────────
//  AppRadii — the three rounded-corner radii used throughout the app.
// ─────────────────────────────────────────────────────────────────────────────

class AppRadii {
  AppRadii._();
  static const double small = 12;
  static const double medium = 16;
  static const double large = 24;
}
