import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/game_content.dart';
import '../game_services.dart';
import '../components/reward_animation.dart';
import '../utils/responsive.dart';
import '../main.dart';

class EmotionalGame extends StatefulWidget {
  final int level;
  final VoidCallback onBack;
  const EmotionalGame({super.key, required this.level, required this.onBack});

  @override
  State<EmotionalGame> createState() => _EmotionalGameState();
}

class _EmotionalGameState extends State<EmotionalGame> {
  int? selectedIndex;
  bool? isCorrect;
  int shakeTrigger = 0;
  Timer? _idleTimer;
  bool _showHint = false;

  int _wrongAttempts = 0;

  bool _showFloatingEmoji = false;
  String _floatingEmoji = '';

  String? _encourageMsg;

  List<Map<String, dynamic>> _shuffledOptions = [];

  void _shuffleOptions() {
    final lang = KidSparkApp.languageNotifier.value;
    final levelData = GameContent.emotionalLevels[lang]![widget.level]
                   ?? GameContent.emotionalLevels[lang]![1]!;
    _shuffledOptions = List<Map<String, dynamic>>.from(levelData['options'] as List);
    _shuffledOptions.shuffle();
  }

  @override
  void initState() {
    super.initState();
    _shuffleOptions();
    _resetIdleTimer();
    KidSparkApp.languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    KidSparkApp.languageNotifier.removeListener(_onLanguageChanged);
    _idleTimer?.cancel();
    AudioManager().stopSpeaking();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      _shuffleOptions();
      setState(() {
        selectedIndex = null;
        isCorrect = null;
        _showFloatingEmoji = false;
        _encourageMsg = null;
      });
    }
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    setState(() => _showHint = false);
    _idleTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && selectedIndex == null) {
        setState(() => _showHint = true);
      }
    });
  }

  String _getEncouragement(String lang) {
    switch (lang) {
      case 'ms': return "Hampir! Cuba lagi!";
      case 'zh': return "差一点！再试试！";
      default:   return "Almost there! Try again!";
    }
  }

  void _handleOption(Map<String, dynamic> option, int index, String lang) {
    if (selectedIndex != null) return;
    _resetIdleTimer();
    unawaited(AudioManager().speak(option['label'] as String, lang));

    setState(() {
      selectedIndex = index;
      isCorrect = option['correct'] as bool;
    });

    if (option['correct'] == true) {
      unawaited(AudioManager().playSfx('correct.mp3'));
      setState(() {
        _floatingEmoji = option['emoji'] as String;
        _showFloatingEmoji = true;
        _encourageMsg = null;
      });

      final stars = ProgressService.calculateStars(_wrongAttempts);
      unawaited(ProgressService().unlockLevel('emotional', widget.level + 1));
      unawaited(ProgressService().saveStars('emotional', widget.level, stars));

      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => RewardDialog(
              starsEarned: stars,
              lang: lang,
              onContinue: () {
                Navigator.of(dialogContext, rootNavigator: true).pop();
                widget.onBack();
              },
            ),
          );
        }
      });
    } else {
      _wrongAttempts++;
      setState(() {
        shakeTrigger++;
        _encourageMsg = _getEncouragement(lang);
      });
      HapticFeedback.vibrate();
      unawaited(AudioManager().playSfx('wrong.mp3'));

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            selectedIndex = null;
            isCorrect = null;
            _showFloatingEmoji = false;
          });
          _resetIdleTimer();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return ValueListenableBuilder<String>(
      valueListenable: KidSparkApp.languageNotifier,
      builder: (context, lang, child) {
        final t = GameContent.translations[lang]!;
        final levelData =
            GameContent.emotionalLevels[lang]![widget.level] ?? GameContent.emotionalLevels[lang]![1]!;

        final String imagePath = levelData['image'] as String;
        final bool isOnline = imagePath.startsWith('http');

        return Material(
          color: const Color(0xFFF0F9FF),
          child: Stack(
            children: [
              Row(
                children: [
                  // ── Left: image + scenario ──────────────────────────
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: EdgeInsets.all(r.dp(12)),
                      child: Column(
                        children: [
                          Text(
                            t['emotional']!,
                            style: TextStyle(
                                fontSize: r.sp(20), fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: r.dp(8)),

                          // Scene image
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(r.dp(20)),
                              child: isOnline
                                  ? CachedNetworkImage(
                                      imageUrl: imagePath,
                                      fit: BoxFit.cover,
                                      width: double.infinity)
                                  : Image.asset(imagePath,
                                      fit: BoxFit.cover, width: double.infinity),
                            ),
                          ),
                          SizedBox(height: r.dp(10)),

                          // Scenario label + speaker
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: r.dp(14), vertical: r.dp(8)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(r.dp(16)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05), blurRadius: 6)
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    levelData['scenario'] as String,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: r.sp(16),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                      color: Colors.blue[50], shape: BoxShape.circle),
                                  child: IconButton(
                                    icon: Icon(Icons.volume_up_rounded,
                                        color: Colors.blueAccent, size: r.icon(26)),
                                    onPressed: () {
                                      _resetIdleTimer();
                                      unawaited(AudioManager()
                                          .speak(levelData['scenario'] as String, lang));
                                    },
                                  ),
                                ).animate(target: _showHint ? 1 : 0)
                                    .shimmer(duration: 1.5.seconds, color: Colors.white),
                              ],
                            ),
                          ).animate(target: shakeTrigger > 0 ? 1 : 0,
                                  onComplete: (c) => shakeTrigger = 0)
                              .shake(hz: 4),
                          SizedBox(height: r.dp(8)),

                          _buildAttemptIndicator(r),
                        ],
                      ),
                    ),
                  ),

                  // ── Right: emotion choices ──────────────────────────
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: EdgeInsets.all(r.dp(20)),
                      child: Column(
                        children: [
                          Text(
                            t['howFeel'] ?? "How do they feel?",
                            style: TextStyle(
                                fontSize: r.sp(20),
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey),
                          ),
                          SizedBox(height: r.dp(4)),

                          if (_encourageMsg != null)
                            Padding(
                              padding: EdgeInsets.only(bottom: r.dp(4)),
                              child: Text(
                                _encourageMsg!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: r.sp(14),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),

                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              childAspectRatio: r.isTablet ? 1.8 : 1.6,
                              mainAxisSpacing: r.dp(10),
                              crossAxisSpacing: r.dp(10),
                              physics: const NeverScrollableScrollPhysics(),
                              children: List.generate(_shuffledOptions.length, (index) {
                                final opt = _shuffledOptions[index];
                                return _buildEmotionTile(opt, index, lang, r);
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Floating emoji celebration
              if (_showFloatingEmoji)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Text(
                        _floatingEmoji,
                        style: TextStyle(fontSize: r.sp(80)),
                      )
                          .animate(onComplete: (_) {
                            if (mounted) setState(() => _showFloatingEmoji = false);
                          })
                          .moveY(begin: 0, end: -100, duration: 900.ms, curve: Curves.easeOut)
                          .fadeOut(begin: 0.8, duration: 900.ms),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttemptIndicator(Responsive r) {
    final stars = ProgressService.calculateStars(_wrongAttempts);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.dp(12), vertical: r.dp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.dp(14)),
        border: Border.all(color: Colors.orange[200]!, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: r.dp(2)),
            child: Icon(
              i < stars ? Icons.star_rounded : Icons.star_border_rounded,
              size: r.icon(22),
              color: i < stars ? Colors.orange : Colors.grey[400],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmotionTile(Map<String, dynamic> opt, int index, String lang, Responsive r) {
    final bool isSelected = selectedIndex == index;
    final bool isThisCorrect = isSelected && isCorrect == true;
    final bool isThisWrong = isSelected && isCorrect == false;

    Color bgColor = isThisCorrect
        ? Colors.green[100]!
        : (isThisWrong ? Colors.red[100]! : Colors.white);
    Color borderColor = isThisCorrect
        ? Colors.green
        : (isThisWrong ? Colors.red : Colors.blue[100]!);

    return GestureDetector(
      onTap: () => _handleOption(opt, index, lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(r.dp(22)),
          border: Border.all(color: borderColor, width: r.dp(3)),
          boxShadow: [
            BoxShadow(
              color: isThisCorrect
                  ? Colors.green.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isThisCorrect)
              Positioned(
                top: r.dp(8),
                right: r.dp(8),
                child: Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: r.icon(22))
                    .animate()
                    .scale(duration: 300.ms, curve: Curves.elasticOut),
              ),
            if (isThisWrong)
              Positioned(
                top: r.dp(8),
                right: r.dp(8),
                child: Icon(Icons.cancel_rounded, color: Colors.red, size: r.icon(22))
                    .animate()
                    .scale(duration: 300.ms),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  opt['emoji'] as String,
                  style: TextStyle(
                    fontSize: isSelected ? r.sp(46) : r.sp(40),
                  ),
                ).animate(target: isThisCorrect ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 400.ms,
                      curve: Curves.elasticOut),
                SizedBox(width: r.dp(10)),
                Flexible(
                  child: Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: r.sp(17),
                      color: isThisCorrect
                          ? Colors.green[800]
                          : (isThisWrong ? Colors.red[800] : Colors.black87),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      )
          .animate(target: _showHint ? 1 : 0)
          .shimmer(duration: 1.5.seconds, color: Colors.blue[100]),
    );
  }
}
