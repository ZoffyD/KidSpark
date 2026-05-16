/// Word Builder mini-game. Player taps letter / syllable tiles to build the
/// target word shown above an illustration. Tracks wrong attempts to award
/// 1–3 stars on completion via `ProgressService.calculateStars`.
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

class WordBuilderGame extends StatefulWidget {
  final int level;
  final VoidCallback onBack;
  const WordBuilderGame({super.key, required this.level, required this.onBack});

  @override
  State<WordBuilderGame> createState() => _WordBuilderGameState();
}

class _WordBuilderGameState extends State<WordBuilderGame> {
  List<String> selectedWords = [];
  List<String> availableWords = [];
  bool? isCorrect;
  int shakeTrigger = 0;

  Timer? _idleTimer;
  bool _showHint = false;

  int _wrongAttempts = 0;
  String? _encourageMsg;

  @override
  void initState() {
    super.initState();
    _loadLevelData();
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
      setState(() {
        selectedWords.clear();
        isCorrect = null;
        _encourageMsg = null;
        _loadLevelData();
      });
    }
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    setState(() => _showHint = false);
    _idleTimer = Timer(const Duration(seconds: 20), () {
      if (mounted) {
        setState(() => _showHint = true);
      }
    });
  }

  String? _nextExpectedLetter(Map<String, dynamic> levelData) {
    final correctLetters = (levelData['correctSentence'] as String).split(' ');
    if (selectedWords.length >= correctLetters.length) return null;
    for (int i = 0; i < selectedWords.length; i++) {
      if (selectedWords[i] != correctLetters[i]) return null;
    }
    return correctLetters[selectedWords.length];
  }

  /// Returns the index of the first wrongly-placed letter in [selectedWords],
  /// or -1 if everything placed so far is a correct prefix.
  int _firstWrongChipIndex(Map<String, dynamic> levelData) {
    final correctLetters = (levelData['correctSentence'] as String).split(' ');
    for (int i = 0; i < selectedWords.length; i++) {
      if (i >= correctLetters.length) return i;
      if (selectedWords[i] != correctLetters[i]) return i;
    }
    return -1;
  }

  void _loadLevelData() {
    final lang = KidSparkApp.languageNotifier.value;
    final data =
        GameContent.wordBuilderLevels[lang]![widget.level] ??
        GameContent.wordBuilderLevels[lang]![1]!;
    availableWords = List<String>.from(data['words'] as List)..shuffle();
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

  void _handleCheck(Map<String, dynamic> levelData, String lang) {
    if (isCorrect != null) return; // already showing feedback
    _resetIdleTimer();
    final sentence = selectedWords.join(' ');

    if (sentence == levelData['correctSentence']) {
      setState(() {
        isCorrect = true;
        _encourageMsg = null;
      });
      unawaited(AudioManager().playSfx('correct.mp3'));
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          unawaited(
            AudioManager().speak(levelData['greeting'] as String, lang),
          );
        }
      });

      final stars = ProgressService.calculateStars(_wrongAttempts);
      unawaited(ProgressService().unlockLevel('word', widget.level + 1));
      unawaited(ProgressService().saveStars('word', widget.level, stars));

      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => RewardDialog(
              starsEarned: stars,
              lang: lang,
              onContinue: () {
                Navigator.pop(ctx);
                widget.onBack();
              },
            ),
          );
        }
      });
    } else {
      _wrongAttempts++;
      setState(() {
        isCorrect = false;
        shakeTrigger++;
        _encourageMsg = _getEncouragement(lang);
      });
      HapticFeedback.mediumImpact();
      unawaited(AudioManager().playSfx('wrong.mp3'));

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            isCorrect = null;
            availableWords.addAll(selectedWords);
            selectedWords.clear();
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
            GameContent.wordBuilderLevels[lang]![widget.level] ??
            GameContent.wordBuilderLevels[lang]![1]!;
        final String imagePath = levelData['image'] as String;
        final String? nextHintLetter = _nextExpectedLetter(levelData);
        final int hintTileIdx = (_showHint && nextHintLetter != null)
            ? availableWords.indexOf(nextHintLetter)
            : -1;
        final int wrongChipIdx = _showHint
            ? _firstWrongChipIndex(levelData)
            : -1;

        return Material(
          color: AppColors.wordBg,
          child: Row(
            children: [
              // ── Left: image + word label ─────────
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.all(r.dp(12)),
                  child: Column(
                    children: [
                      Text(
                        t['wordBuilder'] ?? 'Words',
                        style: TextStyle(
                          fontSize: r.sp(18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: r.dp(4)),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: r.dp(14),
                          vertical: r.dp(10),
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.pink[100]!, Colors.purple[100]!],
                          ),
                          borderRadius: BorderRadius.circular(r.dp(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              levelData['flag'] as String,
                              style: TextStyle(fontSize: r.sp(28)),
                            ),
                            SizedBox(width: r.dp(10)),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: Text(
                                  levelData['greeting'] as String,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                  style: TextStyle(
                                    fontSize: r.sp(18),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            SizedBox(width: r.dp(10)),
                            Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: r.dp(36),
                                      minHeight: r.dp(36),
                                    ),
                                    icon: Icon(
                                      Icons.volume_up_rounded,
                                      color: Colors.pinkAccent,
                                      size: r.icon(24),
                                    ),
                                    onPressed: () {
                                      _resetIdleTimer();
                                      unawaited(
                                        AudioManager().speak(
                                          levelData['greeting'] as String,
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
                      ),
                      SizedBox(height: r.dp(10)),

                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(r.dp(20)),
                          child: Image.asset(imagePath, fit: BoxFit.cover),
                        ),
                      ),
                      SizedBox(height: r.dp(8)),

                      _buildAttemptIndicator(r),
                    ],
                  ),
                ),
              ),

              // ── Right: word builder ─────────────────────────────────
              Expanded(
                flex: 6,
                child: Container(
                  margin: EdgeInsets.all(r.dp(12)),
                  padding: EdgeInsets.all(r.dp(20)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(r.dp(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        t['buildWord']!,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: r.sp(17),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: r.dp(8)),

                      if (_encourageMsg != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: r.dp(8)),
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

                      Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                constraints: BoxConstraints(
                                  minHeight: r.dp(80),
                                ),
                                padding: EdgeInsets.all(r.dp(12)),
                                decoration: BoxDecoration(
                                  color: isCorrect == false
                                      ? Colors.red[100]
                                      : (isCorrect == true
                                            ? Colors.green[100]
                                            : Colors.grey[50]),
                                  borderRadius: BorderRadius.circular(r.dp(20)),
                                  border: Border.all(
                                    color: isCorrect == false
                                        ? Colors.red[700]!
                                        : (isCorrect == true
                                              ? Colors.green[700]!
                                              : Colors.pink[100]!),
                                    width: isCorrect != null
                                        ? r.dp(5)
                                        : r.dp(3),
                                  ),
                                  boxShadow: isCorrect != null
                                      ? [
                                          BoxShadow(
                                            color:
                                                (isCorrect == true
                                                        ? Colors.green
                                                        : Colors.red)
                                                    .withValues(alpha: 0.35),
                                            blurRadius: 16,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: selectedWords.isEmpty
                                    ? Center(
                                        child: Text(
                                          lang == 'zh'
                                              ? "在这里点击词语..."
                                              : (lang == 'ms'
                                                    ? "Tekan perkataan di bawah..."
                                                    : "Tap words below..."),
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: r.sp(15),
                                          ),
                                        ),
                                      )
                                    : LayoutBuilder(
                                        builder: (context, constraints) {
                                          final int n = selectedWords.length;
                                          final double spacing = r.dp(8);
                                          final double maxTile = r.dp(56);
                                          final double minTile = r.dp(26);
                                          double tileSize =
                                              (constraints.maxWidth -
                                                  spacing * (n - 1)) /
                                              n;
                                          tileSize = tileSize.clamp(
                                            minTile,
                                            maxTile,
                                          );
                                          final double fontSize =
                                              (tileSize * 0.46).clamp(
                                                12.0,
                                                24.0,
                                              );
                                          final double radius = tileSize * 0.25;

                                          final children = <Widget>[];
                                          for (
                                            int i = 0;
                                            i < selectedWords.length;
                                            i++
                                          ) {
                                            if (i > 0) {
                                              children.add(
                                                SizedBox(width: spacing),
                                              );
                                            }
                                            final int idx = i;
                                            final String value =
                                                selectedWords[i];
                                            final bool isWrongHint =
                                                idx == wrongChipIdx;
                                            final double badgeSize =
                                                tileSize * 0.42;
                                            Widget chip = GestureDetector(
                                              onTap: () {
                                                _resetIdleTimer();
                                                setState(() {
                                                  selectedWords.removeAt(idx);
                                                  availableWords.add(value);
                                                });
                                              },
                                              child: Container(
                                                width: tileSize,
                                                height: tileSize,
                                                decoration: BoxDecoration(
                                                  color: isWrongHint
                                                      ? Colors.red[700]
                                                      : Colors.pinkAccent,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        radius,
                                                      ),
                                                  border: isWrongHint
                                                      ? Border.all(
                                                          color:
                                                              Colors.red[900]!,
                                                          width: 3,
                                                        )
                                                      : null,
                                                  boxShadow: isWrongHint
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.red
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                ),
                                                            blurRadius: 12,
                                                            spreadRadius: 2,
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    Center(
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          value,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: fontSize,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    if (isWrongHint)
                                                      Positioned(
                                                        top: -badgeSize * 0.25,
                                                        right:
                                                            -badgeSize * 0.25,
                                                        child: Container(
                                                          width: badgeSize,
                                                          height: badgeSize,
                                                          decoration:
                                                              BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                  color: Colors
                                                                      .red[900]!,
                                                                  width: 2,
                                                                ),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .black
                                                                        .withValues(
                                                                          alpha:
                                                                              0.2,
                                                                        ),
                                                                    blurRadius:
                                                                        4,
                                                                  ),
                                                                ],
                                                              ),
                                                          child: Icon(
                                                            Icons.close_rounded,
                                                            color: Colors
                                                                .red[700],
                                                            size:
                                                                badgeSize *
                                                                0.75,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                            if (isWrongHint) {
                                              chip = chip
                                                  .animate(
                                                    onPlay: (c) => c.repeat(),
                                                  )
                                                  .shake(
                                                    duration: 500.ms,
                                                    hz: 4,
                                                    offset: const Offset(10, 0),
                                                    curve: Curves.easeInOut,
                                                  )
                                                  .scaleXY(
                                                    begin: 1.0,
                                                    end: 1.12,
                                                    duration: 250.ms,
                                                    curve: Curves.easeInOut,
                                                  )
                                                  .then()
                                                  .scaleXY(
                                                    begin: 1.12,
                                                    end: 1.0,
                                                    duration: 250.ms,
                                                    curve: Curves.easeInOut,
                                                  )
                                                  .then(delay: 200.ms)
                                                  .shake(
                                                    duration: 500.ms,
                                                    hz: 4,
                                                    offset: const Offset(10, 0),
                                                    curve: Curves.easeInOut,
                                                  )
                                                  .then(delay: 200.ms)
                                                  .shake(
                                                    duration: 500.ms,
                                                    hz: 4,
                                                    offset: const Offset(10, 0),
                                                    curve: Curves.easeInOut,
                                                  )
                                                  .scaleXY(
                                                    begin: 1.0,
                                                    end: 1.0,
                                                    duration: 18000.ms,
                                                  );
                                            }
                                            children.add(chip);
                                          }

                                          return FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: children,
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              if (isCorrect == true)
                                Positioned(
                                  right: r.dp(12),
                                  child:
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green[700],
                                        size: r.icon(56),
                                      ).animate().scale(
                                        begin: const Offset(0.3, 0.3),
                                        end: const Offset(1, 1),
                                        duration: 350.ms,
                                        curve: Curves.elasticOut,
                                      ),
                                ),
                              if (isCorrect == false)
                                Positioned(
                                  right: r.dp(12),
                                  child:
                                      Icon(
                                        Icons.cancel_rounded,
                                        color: Colors.red[700],
                                        size: r.icon(56),
                                      ).animate().scale(
                                        begin: const Offset(0.3, 0.3),
                                        end: const Offset(1, 1),
                                        duration: 300.ms,
                                        curve: Curves.elasticOut,
                                      ),
                                ),
                            ],
                          )
                          .animate(
                            target: shakeTrigger > 0 ? 1 : 0,
                            onComplete: (c) => shakeTrigger = 0,
                          )
                          .shake(
                            hz: 3,
                            offset: const Offset(4, 0),
                            curve: Curves.easeInOut,
                          ),

                      SizedBox(height: r.dp(16)),

                      // Available word tiles — 1 or 2 rows depending on word length.
                      Expanded(
                        child: Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final int n = availableWords.length;
                              if (n == 0) return const SizedBox.shrink();
                              final double spacing = r.dp(10);
                              final double maxTile = r.dp(64);
                              final double readableMin = r.dp(44);
                              // Try one row first. If tiles would be smaller
                              // than readableMin, split into two rows so each
                              // tile stays comfortably tappable.
                              final double oneRowSize =
                                  (constraints.maxWidth - spacing * (n - 1)) /
                                  n;
                              double tileSize;
                              if (oneRowSize >= readableMin) {
                                tileSize = oneRowSize.clamp(
                                  readableMin,
                                  maxTile,
                                );
                              } else {
                                final int perRow = (n / 2).ceil();
                                tileSize =
                                    ((constraints.maxWidth -
                                                spacing * (perRow - 1)) /
                                            perRow)
                                        .clamp(r.dp(36), maxTile);
                              }
                              final double fontSize = (tileSize * 0.46).clamp(
                                12.0,
                                28.0,
                              );
                              final double borderW = (tileSize * 0.05).clamp(
                                1.5,
                                3.0,
                              );
                              final double radius = tileSize * 0.22;

                              final tiles = availableWords.asMap().entries.map((
                                entry,
                              ) {
                                final int idx = entry.key;
                                final String w = entry.value;
                                final bool isHintTile = idx == hintTileIdx;
                                Widget tile = GestureDetector(
                                  onTap: () {
                                    _resetIdleTimer();
                                    unawaited(AudioManager().speak(w, lang));
                                    setState(() {
                                      availableWords.remove(w);
                                      selectedWords.add(w);
                                    });
                                  },
                                  child: Container(
                                    width: tileSize,
                                    height: tileSize,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isHintTile
                                          ? Colors.blue[50]
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        radius,
                                      ),
                                      border: Border.all(
                                        color: isHintTile
                                            ? Colors.blueAccent
                                            : Colors.pinkAccent,
                                        width: borderW,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.pinkAccent.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        w,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
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
                                      .scaleXY(
                                        begin: 1.0,
                                        end: 1.0,
                                        duration: 20000.ms,
                                      );
                                }
                                return tile;
                              }).toList();

                              return Wrap(
                                alignment: WrapAlignment.center,
                                spacing: spacing,
                                runSpacing: spacing,
                                children: tiles,
                              );
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: r.dp(16)),

                      SizedBox(
                            width: r.dp(180),
                            height: r.dp(46),
                            child: ElevatedButton.icon(
                              onPressed: selectedWords.isEmpty
                                  ? null
                                  : () => _handleCheck(levelData, lang),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[200],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(r.dp(16)),
                                ),
                                elevation: selectedWords.isEmpty ? 0 : 3,
                                padding: EdgeInsets.symmetric(
                                  horizontal: r.dp(12),
                                ),
                              ),
                              icon: Icon(
                                Icons.check_circle_outline_rounded,
                                size: r.icon(20),
                              ),
                              label: Text(
                                t['check']!,
                                style: TextStyle(
                                  fontSize: r.sp(16),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .animate(
                            target: (selectedWords.isNotEmpty && _showHint)
                                ? 1
                                : 0,
                          )
                          .shimmer(duration: 1.5.seconds, color: Colors.white),
                    ],
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
}
