/// All non-UI services for KidSpark in one file. Use Ctrl-F to jump:
///
///   * `class AudioManager`   — music, SFX, TTS, lifecycle hooks
///   * `class ProgressService` — unlocks + stars (local + Firestore)
///   * `class TtsCache`        — pre-renders speech to disk
///   * `void registerGameContent` — feeds game data to the cache at startup
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  AudioManager
//  Singleton that owns every audible thing in KidSpark:
//    * background music (with auto-restart guard)
//    * one-shot SFX
//    * text-to-speech with optional pre-rendered cache
//    * lifecycle hooks so audio stops when the app is backgrounded
// ═════════════════════════════════════════════════════════════════════════════

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _speechPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  final TtsCache _ttsCache = TtsCache();

  bool isMusicOn = true;
  bool isSfxOn = true;
  String? _currentMusicFile;
  String _lastLang = '';
  bool _isPaused = false;
  Timer? _musicGuard;
  int _musicGuardFails = 0;

  // ── Phonetic substitution maps ────────────────────────────────────────────
  static const Map<String, String> _enPhonetics = {
    'KL Tower': 'Kay El Tower',
    'Bunga Raya': 'Boo-ngah Rah-yah',
    'Jalur Gemilang': 'Jah-loor Guh-mee-lahng',
    'Jalur': 'Jah-loor',
    'Gemilang': 'Guh-mee-lahng',
  };

  static const Map<String, String> _msPhonetics = {
    'Menara KL': 'Menara Kuala Lumpur',
    'Roti Canai': 'Roti Canai',
  };

  String _applyPhonetics(String text, String lang) {
    final map = lang == 'ms'
        ? _msPhonetics
        : (lang == 'en' ? _enPhonetics : null);
    if (map == null) return text;
    return map[text] ?? text;
  }

  /// Loads persisted toggles, configures TTS for slower autism-friendly speech,
  /// and starts the music-restart guard timer.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isMusicOn = prefs.getBool(PrefsKeys.music) ?? true;
    isSfxOn = prefs.getBool(PrefsKeys.sfx) ?? true;

    // SFX and speech share the same "don't steal focus" context so they can
    // overlap with each other and with background music. Without this the
    // celebration sound gets cut short the moment TTS starts speaking.
    final coexistContext = AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
    );
    try {
      await _sfxPlayer.setAudioContext(coexistContext);
    } catch (_) {}
    try {
      await _speechPlayer.setAudioContext(coexistContext);
    } catch (_) {}

    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.35);

    if (Platform.isIOS) {
      await _tts.setSharedInstance(true);
      await _tts.awaitSpeakCompletion(false);
    }

    // Restart music if the OS or another audio source has stolen focus.
    // Backs off after 5 consecutive failures so a missing/broken audio asset
    // can never thrash the AudioPlayer.
    _musicGuard = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_isPaused) return;
      if (!isMusicOn || _currentMusicFile == null) return;
      if (_musicPlayer.state == PlayerState.playing) {
        _musicGuardFails = 0;
        return;
      }
      if (_musicGuardFails >= 5) return;
      try {
        await _forceRestartMusic();
        _musicGuardFails = 0;
      } catch (_) {
        _musicGuardFails++;
      }
    });
  }

  // ── App lifecycle hooks ───────────────────────────────────────────────────

  /// Called when the app goes to background. Stops every audio source so
  /// nothing keeps playing while the user is elsewhere.
  Future<void> pauseForBackground() async {
    _isPaused = true;
    try {
      await _tts.stop();
    } catch (_) {}
    try {
      await _musicPlayer.stop();
    } catch (_) {}
    try {
      await _sfxPlayer.stop();
    } catch (_) {}
    try {
      await _speechPlayer.stop();
    } catch (_) {}
  }

  /// Called when the app returns to the foreground. Resumes background music
  /// only if a level had previously started it.
  Future<void> resumeFromBackground() async {
    _isPaused = false;
    if (!isMusicOn || _currentMusicFile == null) return;
    try {
      await _forceRestartMusic();
    } catch (_) {}
  }

  /// Builds a fresh `AudioPlayer` and restarts music on it. This avoids the
  /// silent-fail path where a long-lived player gets into a corrupted state.
  Future<void> _forceRestartMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (_) {}
    try {
      await _musicPlayer.dispose();
    } catch (_) {}
    _musicPlayer = AudioPlayer();
    await _musicPlayer.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.play(
      AssetSource('audio/$_currentMusicFile'),
      volume: 0.15,
    );
  }

  // ── TTS language management ───────────────────────────────────────────────

  final Set<String> _promptedMissingLangs = <String>{};

  String _ttsTagFor(String lang) {
    switch (lang) {
      case 'zh':
        return 'zh-CN';
      case 'ms':
        return 'ms-MY';
      default:
        return 'en-US';
    }
  }

  /// Eagerly applies TTS language + voice parameters so the first spoken word
  /// after a language switch plays with no perceptible latency.
  Future<void> warmUpLanguage(String lang) async {
    try {
      _lastLang = lang;
      switch (lang) {
        case 'zh':
          await _tts.setLanguage('zh-CN');
          await _tts.setSpeechRate(0.35);
          await _tts.setPitch(1.05);
          break;
        case 'ms':
          final available = await _tts.isLanguageAvailable('ms-MY');
          await _tts.setLanguage(available == true ? 'ms-MY' : 'en-US');
          await _tts.setSpeechRate(0.35);
          await _tts.setPitch(1.05);
          break;
        default:
          await _tts.setLanguage('en-US');
          await _tts.setSpeechRate(0.38);
          await _tts.setPitch(1.15);
      }
    } catch (_) {}
  }

  /// Returns true if the platform TTS engine has voice data for [lang].
  Future<bool> isLanguageReady(String lang) async {
    try {
      final res = await _tts.isLanguageAvailable(_ttsTagFor(lang));
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// If the language pack is missing, prompts the user once and (on confirm)
  /// launches Android's TTS-data installer. No-op on iOS / web / unknown.
  Future<void> ensureLanguageOrPrompt(BuildContext context, String lang) async {
    if (!Platform.isAndroid) return;
    if (lang == 'en') return;
    if (_promptedMissingLangs.contains(lang)) return;
    if (await isLanguageReady(lang)) return;

    _promptedMissingLangs.add(lang);
    if (!context.mounted) return;

    final langName = lang == 'ms'
        ? 'Bahasa Melayu'
        : (lang == 'zh' ? '中文' : lang);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Install $langName voice?'),
        content: Text(
          'Your device does not have the $langName speech voice yet. '
          'Tap "Install" to open Android\'s voice settings and download it. '
          'After downloading, return to KidSpark to hear $langName.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Install'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      try {
        const intent = AndroidIntent(
          action: 'android.speech.tts.engine.INSTALL_TTS_DATA',
          flags: <int>[0x10000000], // FLAG_ACTIVITY_NEW_TASK
        );
        await intent.launch();
      } catch (_) {
        try {
          const fallback = AndroidIntent(
            action: 'com.android.settings.TTS_SETTINGS',
            flags: <int>[0x10000000],
          );
          await fallback.launch();
        } catch (_) {}
      }
    }
  }

  // ── Speech ────────────────────────────────────────────────────────────────

  /// Speaks [text] in [lang]. Tries the pre-rendered cache first for instant
  /// playback; falls back to the live TTS engine if the phrase is unknown.
  Future<void> speak(String text, String lang) async {
    if (!isSfxOn) return;

    final phonetic = _applyPhonetics(text, lang);

    final cachedPath = _ttsCache.lookup(phonetic, lang);
    if (cachedPath != null) {
      try {
        await _tts.stop();
        await _speechPlayer.stop();
        await _speechPlayer.play(DeviceFileSource(cachedPath), volume: 1.0);
        return;
      } catch (_) {
        // fall through to live TTS
      }
    }

    if (_lastLang != lang) {
      _lastLang = lang;
      switch (lang) {
        case 'zh':
          await _tts.setLanguage('zh-CN');
          await _tts.setSpeechRate(0.35);
          await _tts.setPitch(1.05);
          break;
        case 'ms':
          final available = await _tts.isLanguageAvailable('ms-MY');
          await _tts.setLanguage(available == true ? 'ms-MY' : 'en-US');
          await _tts.setSpeechRate(0.35);
          await _tts.setPitch(1.05);
          break;
        default:
          await _tts.setLanguage('en-US');
          await _tts.setSpeechRate(0.38);
          await _tts.setPitch(1.15);
      }
    }

    await _tts.stop();
    await _tts.speak(phonetic);
  }

  /// Pre-renders every game phrase to disk. Idempotent.
  Future<void> buildSpeechCache({void Function(double)? onProgress}) async {
    await _ttsCache.build(_tts, onProgress: onProgress);
  }

  bool get isSpeechCacheReady => _ttsCache.isReady;

  /// Speaks after a short delay — used for encouragement messages.
  Future<void> speakWithDelay(
    String text,
    String lang, {
    int delayMs = 400,
  }) async {
    await Future.delayed(Duration(milliseconds: delayMs));
    await speak(text, lang);
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    try {
      await _speechPlayer.stop();
    } catch (_) {}
  }

  // ── Background music ──────────────────────────────────────────────────────

  Future<void> playBackgroundMusic(String fileName) async {
    _currentMusicFile = fileName;
    if (!isMusicOn) return;
    if (_musicPlayer.state == PlayerState.playing) return;
    try {
      await _forceRestartMusic();
    } catch (e) {
      if (kDebugMode) debugPrint('Music error: $e');
    }
  }

  // ── Sound effects ─────────────────────────────────────────────────────────

  Future<void> playSfx(String fileName) async {
    if (!isSfxOn) return;
    try {
      try {
        await _sfxPlayer.stop();
      } catch (_) {}
      await _sfxPlayer.play(AssetSource('audio/$fileName'), volume: 1.0);
    } catch (e) {
      if (kDebugMode) debugPrint('SFX error: $e');
    }
  }

  Future<void> stopBackgroundMusic() async {
    _currentMusicFile = null;
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  Future<void> toggleMusic(bool isOn) async {
    isMusicOn = isOn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.music, isOn);
    if (isOn) {
      _currentMusicFile ??= 'map.mp3';
      await _forceRestartMusic();
    } else {
      try {
        await _musicPlayer.stop();
      } catch (_) {}
    }
  }

  Future<void> toggleSfx(bool isOn) async {
    isSfxOn = isOn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.sfx, isOn);
    if (!isOn) {
      try {
        await _sfxPlayer.stop();
      } catch (_) {}
      try {
        await _tts.stop();
      } catch (_) {}
      try {
        await _speechPlayer.stop();
      } catch (_) {}
    }
  }

  /// Stops the music-restart guard. Currently only called from tests.
  void disposeGuard() {
    _musicGuard?.cancel();
    _musicGuard = null;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  ProgressService
//  Persists per-user progress: highest unlocked level and stars per level.
//  Writes are local-first (SharedPreferences) and mirrored to Firestore on a
//  best-effort basis so the app keeps working offline. Auth uses anonymous
//  Firebase sign-in; no PII is ever stored.
// ═════════════════════════════════════════════════════════════════════════════

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Signs the user in anonymously (if not already signed in) and seeds the
  /// `/users/{uid}` document with default progress on first launch.
  Future<void> init() async {
    if (_auth.currentUser == null) {
      try {
        await _auth.signInAnonymously();
      } catch (e) {
        if (kDebugMode) debugPrint('Auth error: $e');
      }
    }
    final user = _auth.currentUser;
    if (user != null) {
      final ref = _db.collection('users').doc(user.uid);
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        await ref.set({
          'created_at': FieldValue.serverTimestamp(),
          'status': 'Player Active',
          PrefsKeys.wordUnlocked: 1,
          PrefsKeys.emotionalUnlocked: 1,
          PrefsKeys.problemUnlocked: 1,
        });
      }
    }
  }

  /// Marks [level] as unlocked for [gameType], if it is higher than the
  /// existing high-water mark. Writes locally first, then mirrors to Firestore.
  Future<void> unlockLevel(String gameType, int level) async {
    final prefs = await SharedPreferences.getInstance();
    final key = PrefsKeys.unlockedFor(gameType);
    final current = prefs.getInt(key) ?? 1;
    if (level > current) {
      await prefs.setInt(key, level);
      await _mirrorToFirestore({key: level});
    }
  }

  /// Records the best-ever star rating earned for a specific level. Lower
  /// scores never overwrite higher ones.
  Future<void> saveStars(String gameType, int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final key = PrefsKeys.starsFor(gameType, level);
    final existing = prefs.getInt(key) ?? 0;
    if (stars > existing) {
      await prefs.setInt(key, stars);
      await _mirrorToFirestore({key: stars});
    }
  }

  /// Best-effort Firestore mirror for [fields]. Catches any error so a network
  /// blip or rule rejection never bubbles up into the gameplay flow.
  Future<void> _mirrorToFirestore(Map<String, Object> fields) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).set({
        ...fields,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('Firestore mirror error: $e');
    }
  }

  /// Returns the best star rating earned for [gameType] level [level].
  /// Returns 0 when the level has never been completed.
  Future<int> getStars(String gameType, int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(PrefsKeys.starsFor(gameType, level)) ?? 0;
  }

  /// Sums the stars earned across every level of [gameType].
  Future<int> getTotalStars(String gameType, int totalLevels) async {
    final prefs = await SharedPreferences.getInstance();
    int total = 0;
    for (int i = 1; i <= totalLevels; i++) {
      total += prefs.getInt(PrefsKeys.starsFor(gameType, i)) ?? 0;
    }
    return total;
  }

  /// Maps wrong-attempt count to a star rating.
  ///
  ///   * 0–3 wrong → 3 stars
  ///   * 4–6 wrong → 2 stars
  ///   * 7+  wrong → 1 star
  static int calculateStars(int wrongAttempts) {
    if (wrongAttempts < 4) return 3;
    if (wrongAttempts < 7) return 2;
    return 1;
  }

  /// Pulls the user's Firestore doc and overwrites local prefs with anything
  /// newer. Called once at startup so a user who reinstalls keeps their
  /// progress.
  Future<void> syncProgress() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      for (final entry in data.entries) {
        if (entry.key.startsWith('kidspark_') && entry.value is int) {
          await prefs.setInt(entry.key, entry.value as int);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Sync error: $e');
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TtsCache
//  Pre-renders every game phrase to a local audio file so that
//  AudioManager.speak() plays back instantly with zero engine latency,
//  regardless of language switches.
//
//  The cache is keyed by `lang|text` and stored under the app cache directory.
//  Bumping `_version` invalidates the on-disk cache.
// ═════════════════════════════════════════════════════════════════════════════

class TtsCache {
  static const int _version = 1;
  static String get _readyPrefKey => PrefsKeys.ttsCacheReady(_version);

  final Map<String, String> _index = {}; // "lang|text" → absolute file path
  bool _ready = false;
  Directory? _dir;

  bool get isReady => _ready;

  /// Returns the cached file path for [text] in [lang], or null if missing.
  String? lookup(String text, String lang) {
    if (!_ready) return null;
    return _index['$lang|$text'];
  }

  Future<Directory> _ensureDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationCacheDirectory();
    final d = Directory('${base.path}/tts_cache_v$_version');
    if (!await d.exists()) await d.create(recursive: true);
    _dir = d;
    return d;
  }

  String _fileFor(String text, String lang, Directory dir) {
    final hash = sha1
        .convert(utf8.encode('$lang|$text'))
        .toString()
        .substring(0, 16);
    final ext = Platform.isIOS ? 'caf' : 'wav';
    return '${dir.path}/$hash.$ext';
  }

  /// Collects every phrase the app might pass to `speak()`, keyed by language.
  List<_Phrase> _collectPhrases() {
    final phrases = <_Phrase>{};

    final translations = _GameContentBridge.translations;
    final wordLevels = _GameContentBridge.wordBuilderLevels;
    final emoLevels = _GameContentBridge.emotionalLevels;
    final probLevels = _GameContentBridge.problemLevels;

    for (final lang in const ['en', 'ms', 'zh']) {
      final tx = translations[lang];
      if (tx != null) {
        for (final v in tx.values) {
          phrases.add(_Phrase(_stripEmojis(v), lang));
        }
      }

      final wl = wordLevels[lang];
      if (wl != null) {
        for (final lvl in wl.values) {
          final m = lvl as Map;
          phrases.add(_Phrase(m['greeting'] as String, lang));
          for (final w in (m['words'] as List)) {
            phrases.add(_Phrase(w as String, lang));
          }
        }
      }

      final el = emoLevels[lang];
      if (el != null) {
        for (final lvl in el.values) {
          final m = lvl as Map;
          phrases.add(_Phrase(m['scenario'] as String, lang));
          for (final opt in (m['options'] as List)) {
            phrases.add(_Phrase((opt as Map)['label'] as String, lang));
          }
        }
      }

      final pl = probLevels[lang];
      if (pl != null) {
        for (final lvl in pl.values) {
          final m = lvl as Map;
          phrases.add(_Phrase(m['name'] as String, lang));
          for (final opt in (m['options'] as List)) {
            phrases.add(_Phrase((opt as Map)['label'] as String, lang));
          }
        }
      }
    }

    return phrases.toList(growable: false);
  }

  static String _stripEmojis(String s) {
    return s
        .replaceAll(
          RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true),
          '',
        )
        .trim();
  }

  /// Pre-renders every phrase. Idempotent: phrases already on disk are skipped.
  /// Once at least 80% of phrases render successfully, the cache is marked
  /// ready in prefs so future launches skip this step.
  Future<void> build(
    FlutterTts tts, {
    void Function(double)? onProgress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final dir = await _ensureDir();
    final phrases = _collectPhrases();

    int present = 0;
    for (final p in phrases) {
      if (p.text.isEmpty) {
        present++;
        continue;
      }
      final path = _fileFor(p.text, p.lang, dir);
      if (await File(path).exists()) {
        _index['${p.lang}|${p.text}'] = path;
        present++;
      }
    }

    if (present == phrases.length && (prefs.getBool(_readyPrefKey) ?? false)) {
      _ready = true;
      onProgress?.call(1.0);
      return;
    }

    try {
      await tts.awaitSynthCompletion(true);
    } catch (_) {}

    String? activeLang;
    int done = present;
    final total = phrases.length;
    onProgress?.call(total == 0 ? 1.0 : done / total);

    for (final p in phrases) {
      if (p.text.isEmpty) continue;
      final key = '${p.lang}|${p.text}';
      final path = _fileFor(p.text, p.lang, dir);

      if (_index.containsKey(key)) continue;
      if (await File(path).exists()) {
        _index[key] = path;
        done++;
        onProgress?.call(done / total);
        continue;
      }

      // Switch the engine to the right language only when it changes.
      if (activeLang != p.lang) {
        activeLang = p.lang;
        try {
          switch (p.lang) {
            case 'zh':
              await tts.setLanguage('zh-CN');
              await tts.setSpeechRate(0.35);
              await tts.setPitch(1.05);
              break;
            case 'ms':
              final ok = await tts.isLanguageAvailable('ms-MY');
              await tts.setLanguage(ok == true ? 'ms-MY' : 'en-US');
              await tts.setSpeechRate(0.35);
              await tts.setPitch(1.05);
              break;
            default:
              await tts.setLanguage('en-US');
              await tts.setSpeechRate(0.38);
              await tts.setPitch(1.15);
          }
        } catch (_) {}
      }

      try {
        await tts.synthesizeToFile(p.text, path, true);
        if (await File(path).exists()) _index[key] = path;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('TTS render failed for "${p.text}" (${p.lang}): $e');
        }
      }

      done++;
      onProgress?.call(done / total);
    }

    try {
      await tts.awaitSynthCompletion(false);
    } catch (_) {}

    final coverage = total == 0 ? 1.0 : _index.length / total;
    _ready = coverage >= 0.8;
    if (_ready) await prefs.setBool(_readyPrefKey, true);
  }
}

class _Phrase {
  final String text;
  final String lang;
  const _Phrase(this.text, this.lang);

  @override
  bool operator ==(Object other) =>
      other is _Phrase && other.text == text && other.lang == lang;

  @override
  int get hashCode => Object.hash(text, lang);
}

/// Lets [TtsCache] read game content without importing it directly. Populated
/// by [registerGameContent] from `main.dart` before `buildSpeechCache()` runs.
class _GameContentBridge {
  static Map<String, Map<String, String>> translations = {};
  static Map<String, Map<int, dynamic>> wordBuilderLevels = {};
  static Map<String, Map<int, dynamic>> emotionalLevels = {};
  static Map<String, Map<int, dynamic>> problemLevels = {};
}

/// Call once at app startup before `AudioManager().buildSpeechCache()`.
void registerGameContent({
  required Map<String, Map<String, String>> translations,
  required Map<String, Map<int, dynamic>> wordBuilderLevels,
  required Map<String, Map<int, dynamic>> emotionalLevels,
  required Map<String, Map<int, dynamic>> problemLevels,
}) {
  _GameContentBridge.translations = translations;
  _GameContentBridge.wordBuilderLevels = wordBuilderLevels;
  _GameContentBridge.emotionalLevels = emotionalLevels;
  _GameContentBridge.problemLevels = problemLevels;
}
