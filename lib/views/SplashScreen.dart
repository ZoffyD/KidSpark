import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/responsive.dart';
import 'dashboard.dart';

class KidSparkSplash extends StatelessWidget {
  const KidSparkSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0FBF5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainDashboard()),
                );
              },
              child: Image.asset('assets/images/logo.png', height: r.dp(160))
                  .animate()
                  .scale(duration: 800.ms, curve: Curves.elasticOut),
            ),
            SizedBox(height: r.dp(30)),
            Text(
              "Tap the logo to start!",
              style: TextStyle(
                fontSize: r.sp(28),
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fade(duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
