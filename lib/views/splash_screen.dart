/// Splash screen shown at app start. Drives the one-time TTS cache build and
/// shows a progress bar while every spoken phrase is pre-rendered to disk.
/// Tap the logo when ready to continue to the dashboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_constants.dart';
import '../core/app_utils.dart';
import '../services/game_services.dart';
import 'dashboard.dart';

class KidSparkSplash extends StatefulWidget {
  const KidSparkSplash({super.key});

  @override
  State<KidSparkSplash> createState() => _KidSparkSplashState();
}

class _KidSparkSplashState extends State<KidSparkSplash> {
  double _progress = 0.0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _prepareSpeechCache();
  }

  Future<void> _prepareSpeechCache() async {
    final am = AudioManager();
    if (am.isSpeechCacheReady) {
      if (mounted) {
        setState(() {
          _ready = true;
          _progress = 1.0;
        });
      }
      return;
    }

    await am.buildSpeechCache(
      onProgress: (p) {
        if (!mounted) return;
        setState(() => _progress = p);
      },
    );

    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _ready
                  ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainDashboard(),
                        ),
                      );
                    }
                  : null,
              child: Image.asset(
                'assets/images/logo.png',
                height: r.dp(160),
              ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
            ),
            SizedBox(height: r.dp(30)),
            if (_ready)
              Text(
                "Tap the logo to start!",
                style: TextStyle(
                  fontSize: r.sp(28),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ).animate().fadeIn(duration: 600.ms)
            else
              Column(
                children: [
                  SizedBox(
                    width: r.dp(220),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(r.dp(8)),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: r.dp(10),
                        backgroundColor: const Color(0xFFD9F0E2),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: r.dp(12)),
                  Text(
                    "Preparing voices… ${(_progress * 100).round()}%",
                    style: TextStyle(
                      fontSize: r.sp(16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
