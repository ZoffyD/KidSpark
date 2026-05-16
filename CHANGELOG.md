# Changelog

All notable changes to KidSpark are recorded in this file.

## [0.2.0]

### Added
- Pre-rendered TTS speech cache so word/feeling/puzzle taps respond instantly,
  even right after a language switch.
- Splash screen progress indicator while the speech cache builds on first
  launch.
- Idle-hint system: after 20 s of inactivity in any game, the correct option
  shimmers / shakes to nudge the player.
- Per-level star tracking (1–3 stars based on number of wrong attempts) with
  a dedicated reward dialog.
- Trilingual coverage (English, Bahasa Melayu, 中文) across every UI string,
  level prompt, and option label.
- Lifecycle-aware audio: music and SFX stop when the app is backgrounded and
  resume cleanly when the user returns.
- Android prompt that opens the system TTS-data installer when a language
  voice pack is missing.

### Changed
- Split the original monolithic `game_services.dart` into three focused
  service files (`AudioManager`, `ProgressService`, `TtsCache`); the old
  path is preserved as a barrel re-export so existing imports keep working.
- Centralised every `SharedPreferences` / Firestore field name in
  `lib/constants/prefs_keys.dart`.
- Centralised the colour palette and corner radii in
  `lib/theme/app_theme.dart`.
- Replaced the per-screen `_label(lang, en, ms, zh)` helper with a single
  shared `tr(...)` function in `lib/utils/i18n.dart`.
- Tightened Firestore rules to allow-list every writable field and deny
  everything outside `/users/{uid}`.

### Removed
- Unused `tiger.png` asset.
- Verbose `debugPrint` lines now compile out of release builds (gated by
  `kDebugMode`).

## [0.1.0]

### Added
- Initial commit: three mini-games, level map dashboard, anonymous Firebase
  progress sync, basic settings screen.
