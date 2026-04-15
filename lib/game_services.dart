import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AUDIO MANAGER  (improved TTS accuracy + child-friendly voice)
// ─────────────────────────────────────────────────────────────────────────────
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer   = AudioPlayer();
  final FlutterTts  _tts         = FlutterTts();

  bool    isMusicOn        = true;
  bool    isSfxOn          = true;
  String? _currentMusicFile;
  String  _lastLang        = '';
  // ignore: unused_field
  Timer?  _musicGuard;

  // ── Phonetic substitution maps ────────────────────────────────────────────
  static const Map<String, String> _enPhonetics = {
    'KL Tower'       : 'Kay El Tower',
    'Bunga Raya'     : 'Boo-ngah Rah-yah',
    'Jalur Gemilang' : 'Jah-loor Guh-mee-lahng',
    'Jalur'          : 'Jah-loor',
    'Gemilang'       : 'Guh-mee-lahng',
  };

  static const Map<String, String> _msPhonetics = {
    'Menara KL'      : 'Menara Kuala Lumpur',
    'Roti Canai'     : 'Roti Canai',
  };

  String _applyPhonetics(String text, String lang) {
    final map = lang == 'ms' ? _msPhonetics : (lang == 'en' ? _enPhonetics : null);
    if (map == null) return text;
    return map[text] ?? text;
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isMusicOn = prefs.getBool('kidspark_music') ?? true;
    isSfxOn   = prefs.getBool('kidspark_sfx')   ?? true;

    // ── TTS setup — slower & clearer for autism-friendly speech ──────────
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.15);
    await _tts.setSpeechRate(0.35);

    if (Platform.isIOS) {
      await _tts.setSharedInstance(true);
      await _tts.awaitSpeakCompletion(false);
    }

    // Periodic guard: if music should be playing but isn't, force-restart
    // with a fresh player. Catches TTS audio focus steal, OS interruption, etc.
    _musicGuard = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!isMusicOn || _currentMusicFile == null) return;
      if (_musicPlayer.state == PlayerState.playing) return;
      try {
        await _forceRestartMusic();
      } catch (_) {}
    });
  }

  /// Create a brand-new AudioPlayer and start music on it.
  /// This avoids the corrupted-state problem where play() silently fails.
  Future<void> _forceRestartMusic() async {
    try { await _musicPlayer.stop(); } catch (_) {}
    try { await _musicPlayer.dispose(); } catch (_) {}
    _musicPlayer = AudioPlayer();
    await _musicPlayer.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake:        true,
        contentType:      AndroidContentType.music,
        usageType:        AndroidUsageType.game,
        audioFocus:       AndroidAudioFocus.none,
      ),
    ));
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.play(
      AssetSource('audio/$_currentMusicFile'),
      volume: 0.15,
    );
  }

  Future<void> speak(String text, String lang) async {
    if (!isSfxOn) return;

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

    final phonetic = _applyPhonetics(text, lang);
    await _tts.stop();
    await _tts.speak(phonetic);
  }

  /// Speak with a brief pause before — good for encouragement messages
  Future<void> speakWithDelay(String text, String lang, {int delayMs = 400}) async {
    await Future.delayed(Duration(milliseconds: delayMs));
    await speak(text, lang);
  }

  Future<void> stopSpeaking() async {
    try { await _tts.stop(); } catch (_) {}
  }

  // ── Background music ──────────────────────────────────────────────────────
  Future<void> playBackgroundMusic(String fileName) async {
    _currentMusicFile = fileName;
    if (!isMusicOn) return;
    // Already playing — leave it alone
    if (_musicPlayer.state == PlayerState.playing) return;
    try {
      await _forceRestartMusic();
    } catch (e) {
      debugPrint('⚠️ Music Error: $e');
    }
  }

  // ── SFX ───────────────────────────────────────────────────────────────────
  Future<void> playSfx(String fileName) async {
    if (!isSfxOn) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/$fileName'), volume: 1.0);
    } catch (e) {
      debugPrint('⚠️ SFX Error: $e');
    }
  }

  Future<void> stopBackgroundMusic() async {
    _currentMusicFile = null;
    try { await _musicPlayer.stop(); } catch (_) {}
  }

  Future<void> toggleMusic(bool isOn) async {
    isMusicOn = isOn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kidspark_music', isOn);
    if (isOn) {
      _currentMusicFile ??= 'map.mp3';
      await _forceRestartMusic();
    } else {
      try { await _musicPlayer.stop(); } catch (_) {}
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROGRESS SERVICE  (now tracks stars per level)
// ─────────────────────────────────────────────────────────────────────────────
class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  final FirebaseAuth      _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db   = FirebaseFirestore.instance;

  Future<void> init() async {
    if (_auth.currentUser == null) {
      try {
        await _auth.signInAnonymously();
      } catch (e) {
        debugPrint('❌ Auth Error: $e');
      }
    }
    final user = _auth.currentUser;
    if (user != null) {
      final ref      = _db.collection('users').doc(user.uid);
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        await ref.set({
          'created_at'                  : FieldValue.serverTimestamp(),
          'status'                      : 'Player Active',
          'kidspark_word_unlocked'      : 1,
          'kidspark_emotional_unlocked' : 1,
          'kidspark_problem_unlocked'   : 1,
        });
      }
    }
  }

  Future<void> unlockLevel(String gameType, int level) async {
    final prefs   = await SharedPreferences.getInstance();
    final key     = 'kidspark_${gameType}_unlocked';
    final current = prefs.getInt(key) ?? 1;
    if (level > current) {
      await prefs.setInt(key, level);
      final user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          key            : level,
          'last_updated' : FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  // ── Star tracking per level ───────────────────────────────────────────────
  /// Save stars earned for a specific game + level
  Future<void> saveStars(String gameType, int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'kidspark_${gameType}_stars_$level';
    final existing = prefs.getInt(key) ?? 0;
    // Only save if new stars are higher (best score)
    if (stars > existing) {
      await prefs.setInt(key, stars);
      final user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          key            : stars,
          'last_updated' : FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  /// Get stars earned for a specific game + level (0 = not completed)
  Future<int> getStars(String gameType, int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('kidspark_${gameType}_stars_$level') ?? 0;
  }

  /// Get total stars across all levels for a game type
  Future<int> getTotalStars(String gameType, int totalLevels) async {
    final prefs = await SharedPreferences.getInstance();
    int total = 0;
    for (int i = 1; i <= totalLevels; i++) {
      total += prefs.getInt('kidspark_${gameType}_stars_$i') ?? 0;
    }
    return total;
  }

  /// Calculate stars based on wrong attempts:
  /// 0-3 wrong = 3 stars, 4-6 wrong = 2 stars, 7+ wrong = 1 star
  static int calculateStars(int wrongAttempts) {
    if (wrongAttempts < 4) return 3;
    if (wrongAttempts < 7) return 2;
    return 1;
  }

  Future<void> syncProgress() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data  = doc.data() as Map<String, dynamic>;
          final prefs = await SharedPreferences.getInstance();
          for (final entry in data.entries) {
            if (entry.key.startsWith('kidspark_')) {
              if (entry.value is int) {
                await prefs.setInt(entry.key, entry.value as int);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Sync Error: $e');
      }
    }
  }
}