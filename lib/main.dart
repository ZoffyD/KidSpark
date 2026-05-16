/// App entry point. Initialises Firebase + offline persistence, builds the
/// service singletons (`AudioManager`, `ProgressService`, `TtsCache`),
/// loads the saved language, locks orientation to landscape, and finally
/// runs `KidSparkApp` whose home is the splash screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/app_constants.dart';
import 'core/game_content.dart';
import 'firebase/firebase_options.dart';
import 'services/game_services.dart';
import 'views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await AudioManager().init();
  await ProgressService().init();
  await ProgressService().syncProgress();

  // Feed the TTS cache so it can pre-render every speakable phrase.
  registerGameContent(
    translations: GameContent.translations,
    wordBuilderLevels: GameContent.wordBuilderLevels,
    emotionalLevels: GameContent.emotionalLevels,
    problemLevels: GameContent.problemLevels,
  );

  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString(PrefsKeys.language) ?? 'en';
  KidSparkApp.languageNotifier.value = savedLang;

  runApp(const KidSparkApp());
}

class KidSparkApp extends StatefulWidget {
  const KidSparkApp({super.key});

  static final ValueNotifier<String> languageNotifier = ValueNotifier('en');

  @override
  State<KidSparkApp> createState() => _KidSparkAppState();
}

class _KidSparkAppState extends State<KidSparkApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AudioManager().resumeFromBackground();
    } else {
      // Any non-resumed state (paused/inactive/hidden/detached) silences
      // audio so nothing keeps running while the user is away.
      AudioManager().pauseForBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KidSpark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.nunito().fontFamily,
        scaffoldBackgroundColor: AppColors.splashBg,
      ),
      home: const KidSparkSplash(),
    );
  }
}
