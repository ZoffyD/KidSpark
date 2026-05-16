/// Feelings mini-game. Shows a scenario image + sentence and asks the player
/// to pick the matching emotion from four emoji+label tiles. Star scoring is
/// shared with the other games via `ProgressService.calculateStars`.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_constants.dart';
import '../core/app_utils.dart';
import '../core/game_content.dart';
import '../main.dart';
import '../services/game_services.dart';
import 'reward_animation.dart';

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
    final levelData =
        GameContent.emotionalLevels[lang]![widget.level] ??
        GameContent.emotionalLevels[lang]![1]!;
    _shuffledOptions = List<Map<String, dynamic>>.from(
      levelData['options'] as List,
    );
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
    _idleTimer = Timer(const Duration(seconds: 20), () {
      if (mounted && selectedIndex == null) {
        setState(() => _showHint = true);
      }
    });
  }

  String _getEncouragement(String lang) {
    switch (lang) {
      case 'ms':
        return "Hampir! Cuba lagi!";
      case 'zh':
        return "差一点！再试试！";
      default:
        return "Almost there! Try again!";
    }
  }

  void _handleOption(Map<String, dynamic> option, int index, String lang) {
    if (selectedIndex != null) return;
    _resetIdleTimer();

    setState(() {
      selectedIndex = index;
      isCorrect = option['correct'] as bool;
    });

    if (option['correct'] == true) {
      // Play the "yay" SFX first so it isn't stolen by the TTS speech.
      unawaited(AudioManager().playSfx('correct.mp3'));
      setState(() {
        _floatingEmoji = option['emoji'] as String;
        _showFloatingEmoji = true;
        _encourageMsg = null;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          unawaited(AudioManager().speak(option['label'] as String, lang));
        }
      });

      final stars = ProgressService.calculateStars(_wrongAttempts);
      unawaited(ProgressService().unlockLevel('emotional', widget.level + 1));
      unawaited(ProgressService().saveStars('emotional', widget.level, stars));

      Future.delayed(const Duration(milliseconds: 1400), () {
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
      HapticFeedback.mediumImpact();
      unawaited(AudioManager().playSfx('wrong.mp3'));
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          unawaited(AudioManager().speak(option['label'] as String, lang));
        }
      });

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
            GameContent.emotionalLevels[lang]![widget.level] ??
            GameContent.emotionalLevels[lang]![1]!;

        final String imagePath = levelData['image'] as String;

        return Material(
          color: AppColors.emotionalBg,
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
                              fontSize: r.sp(20),
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: r.dp(8)),

                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(r.dp(20)),
                              child: Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          SizedBox(height: r.dp(10)),

                          Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: r.dp(14),
                                  vertical: r.dp(8),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(r.dp(16)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 6,
                                    ),
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
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                    Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.volume_up_rounded,
                                              color: Colors.blueAccent,
                                              size: r.icon(26),
                                            ),
                                            onPressed: () {
                                              _resetIdleTimer();
                                              unawaited(
                                                AudioManager().speak(
                                                  levelData['scenario']
                                                      as String,
                                                  lang,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                        .animate(target: _showHint ? 1 : 0)
                                        .shimmer(
                                          duration: 1.5.seconds,
                                          color: Colors.white,
                                        ),
                                  ],
                                ),
                              )
                              .animate(
                                target: shakeTrigger > 0 ? 1 : 0,
                                onComplete: (c) => shakeTrigger = 0,
                              )
                              .shake(hz: 3, offset: const Offset(4, 0)),
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
                              color: Colors.blueGrey,
                            ),
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
                              children: List.generate(_shuffledOptions.length, (
                                index,
                              ) {
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
                      child:
                          Text(
                                _floatingEmoji,
                                style: TextStyle(fontSize: r.sp(80)),
                              )
                              .animate(
                                onComplete: (_) {
                                  if (mounted) {
                                    setState(() => _showFloatingEmoji = false);
                                  }
                                },
                              )
                              .moveY(
                                begin: 0,
                                end: -100,
                                duration: 900.ms,
                                curve: Curves.easeOut,
                              )
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

  Widget _buildEmotionTile(
    Map<String, dynamic> opt,
    int index,
    String lang,
    Responsive r,
  ) {
    final bool isSelected = selectedIndex == index;
    final bool isThisCorrect = isSelected && isCorrect == true;
    final bool isThisWrong = isSelected && isCorrect == false;
    final bool isHintTile =
        _showHint && selectedIndex == null && (opt['correct'] as bool) == true;

    Color bgColor = isThisCorrect
        ? Colors.green[300]!
        : (isThisWrong
              ? Colors.red[300]!
              : (isHintTile ? Colors.blue[50]! : Colors.white));
    Color borderColor = isThisCorrect
        ? Colors.green[700]!
        : (isThisWrong
              ? Colors.red[700]!
              : (isHintTile ? Colors.blueAccent : Colors.blue[100]!));

    Widget tile = GestureDetector(
      onTap: () => _handleOption(opt, index, lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(r.dp(22)),
          border: Border.all(
            color: borderColor,
            width: isSelected ? r.dp(6) : r.dp(3),
          ),
          boxShadow: [
            BoxShadow(
              color: isThisCorrect
                  ? Colors.green.withValues(alpha: 0.45)
                  : (isThisWrong
                        ? Colors.red.withValues(alpha: 0.45)
                        : Colors.black.withValues(alpha: 0.05)),
              blurRadius: isSelected ? 18 : 10,
              spreadRadius: isSelected ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                      opt['emoji'] as String,
                      style: TextStyle(
                        fontSize: isSelected ? r.sp(46) : r.sp(40),
                      ),
                    )
                    .animate(target: isThisCorrect ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.15, 1.15),
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    ),
                SizedBox(width: r.dp(10)),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      opt['label'] as String,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: r.sp(17),
                        color: isThisCorrect
                            ? Colors.white
                            : (isThisWrong ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (isThisCorrect)
              Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: r.icon(72),
              ).animate().scale(
                begin: const Offset(0.3, 0.3),
                end: const Offset(1, 1),
                duration: 350.ms,
                curve: Curves.elasticOut,
              ),
            if (isThisWrong)
              Icon(
                Icons.cancel_rounded,
                color: Colors.white,
                size: r.icon(72),
              ).animate().scale(
                begin: const Offset(0.3, 0.3),
                end: const Offset(1, 1),
                duration: 300.ms,
                curve: Curves.elasticOut,
              ),
          ],
        ),
      ),
    );

    if (isHintTile) {
      tile = tile
          .animate(onPlay: (c) => c.repeat())
          .shake(
            duration: 500.ms,
            hz: 4,
            offset: const Offset(0, 14),
            curve: Curves.easeInOut,
          )
          .then(delay: 200.ms)
          .shake(
            duration: 500.ms,
            hz: 4,
            offset: const Offset(0, 14),
            curve: Curves.easeInOut,
          )
          .then(delay: 200.ms)
          .shake(
            duration: 500.ms,
            hz: 4,
            offset: const Offset(0, 14),
            curve: Curves.easeInOut,
          )
          .scaleXY(begin: 1.0, end: 1.0, duration: 20000.ms);
    }

    return tile;
  }
}
