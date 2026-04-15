import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'game_services.dart';
import 'views/SplashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide status bar and navigation bar for full immersive experience
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Offline Persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize Services
  await AudioManager().init();
  await ProgressService().init();
  await ProgressService().syncProgress();

  // Load saved language
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('kidspark_language') ?? 'en';
  KidSparkApp.languageNotifier.value = savedLang;

  runApp(const KidSparkApp());
}

class KidSparkApp extends StatelessWidget {
  const KidSparkApp({super.key});

  static final ValueNotifier<String> languageNotifier = ValueNotifier('en');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KidSpark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.nunito().fontFamily,
        scaffoldBackgroundColor: const Color(0xFFF0FBF5),
      ),
      home: const KidSparkSplash(),
    );
  }
}