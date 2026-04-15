import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/responsive.dart';

class RewardDialog extends StatelessWidget {
  final int starsEarned;
  final int totalStars;
  final VoidCallback onContinue;
  final String lang;

  const RewardDialog({
    super.key,
    required this.starsEarned,
    this.totalStars = 3,
    required this.onContinue,
    this.lang = 'en',
  });

  String _getMessage() {
    switch (lang) {
      case 'ms':
        if (starsEarned == 3) return "Hebat! Sempurna! 🌟";
        if (starsEarned == 2) return "Bagus! Cuba lagi untuk 3 bintang!";
        return "Tahniah! Kamu boleh!";
      case 'zh':
        if (starsEarned == 3) return "太棒了！满分！🌟";
        if (starsEarned == 2) return "很好！再试试拿3颗星！";
        return "加油！你做到了！";
      default:
        if (starsEarned == 3) return "Amazing! Perfect! 🌟";
        if (starsEarned == 2) return "Good job! Try again for 3 stars!";
        return "Well done! You did it!";
    }
  }

  String _continueLabel() {
    switch (lang) {
      case 'ms': return "Teruskan";
      case 'zh': return "继续";
      default:   return "Continue";
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: r.dp(420),
        padding: EdgeInsets.all(r.dp(20)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.dp(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration_rounded, size: r.icon(64), color: Colors.pinkAccent)
                .animate(onPlay: (c) => c.repeat())
                .shake(duration: 1.seconds),

            SizedBox(height: r.dp(12)),

            Text(
              _getMessage(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: r.sp(22),
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),

            SizedBox(height: r.dp(16)),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalStars, (index) {
                final bool earned = index < starsEarned;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.dp(4)),
                  child: Icon(
                    earned ? Icons.star_rounded : Icons.star_border_rounded,
                    size: r.icon(48),
                    color: earned ? Colors.orange : Colors.grey[300],
                  ).animate().scale(
                    delay: (index * 200).ms,
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),
                );
              }),
            ),

            SizedBox(height: r.dp(20)),

            SizedBox(
              width: double.infinity,
              height: r.dp(52),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(r.dp(18)),
                  ),
                  elevation: 3,
                ),
                onPressed: onContinue,
                child: Text(
                  _continueLabel(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: r.sp(20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
    );
  }
}
