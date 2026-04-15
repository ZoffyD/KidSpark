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
    _idleTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && selectedWords.isEmpty) {
        setState(() => _showHint = true);
      }
    });
  }

  void _loadLevelData() {
    final lang = KidSparkApp.languageNotifier.value;
    final data =
        GameContent.wordBuilderLevels[lang]![widget.level] ?? GameContent.wordBuilderLevels[lang]![1]!;
    availableWords = List<String>.from(data['words'] as List)..shuffle();
  }

  String _getEncouragement(String lang) {
    switch (lang) {
      case 'ms': return "Hampir! Cuba lagi!";
      case 'zh': return "差一点！再试试！";
      default:   return "Almost there! Try again!";
    }
  }

  void _handleCheck(Map<String, dynamic> levelData, String lang) {
    _resetIdleTimer();
    final sentence = selectedWords.join(' ');

    if (sentence == levelData['correctSentence']) {
      setState(() {
        isCorrect = true;
        _encourageMsg = null;
      });
      unawaited(AudioManager().playSfx('correct.mp3'));
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) unawaited(AudioManager().speak(levelData['correctSentence'] as String, lang));
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
      HapticFeedback.vibrate();
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
            GameContent.wordBuilderLevels[lang]![widget.level] ?? GameContent.wordBuilderLevels[lang]![1]!;
        final String imagePath = levelData['image'] as String;
        final bool isOnline = imagePath.startsWith('http');

        return Material(
          color: const Color(0xFFFDF2F8),
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
                        style: TextStyle(fontSize: r.sp(18), fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: r.dp(4)),

                      // Full word display
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: r.dp(14), vertical: r.dp(10)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Colors.pink[100]!, Colors.purple[100]!]),
                          borderRadius: BorderRadius.circular(r.dp(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(levelData['flag'] as String,
                                style: TextStyle(fontSize: r.sp(28))),
                            SizedBox(width: r.dp(10)),
                            Flexible(
                              child: Text(
                                levelData['greeting'] as String,
                                style: TextStyle(
                                    fontSize: r.sp(20),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: r.dp(10)),
                            Container(
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  shape: BoxShape.circle),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(minWidth: r.dp(36), minHeight: r.dp(36)),
                                icon: Icon(Icons.volume_up_rounded,
                                    color: Colors.pinkAccent, size: r.icon(24)),
                                onPressed: () {
                                  _resetIdleTimer();
                                  unawaited(AudioManager()
                                      .speak(levelData['correctSentence'] as String, lang));
                                },
                              ),
                            ).animate(target: _showHint ? 1 : 0)
                                .shimmer(duration: 1.5.seconds, color: Colors.white),
                          ],
                        ),
                      ),
                      SizedBox(height: r.dp(10)),

                      // Image
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(r.dp(20)),
                          child: isOnline
                              ? CachedNetworkImage(imageUrl: imagePath, fit: BoxFit.cover)
                              : Image.asset(imagePath, fit: BoxFit.cover),
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
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        t['buildWord']!,
                        style: TextStyle(
                            color: Colors.grey, fontSize: r.sp(17), fontWeight: FontWeight.bold),
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

                      // Answer area
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        constraints: BoxConstraints(minHeight: r.dp(80)),
                        padding: EdgeInsets.all(r.dp(12)),
                        decoration: BoxDecoration(
                          color: isCorrect == false
                              ? Colors.red[50]
                              : (isCorrect == true ? Colors.green[50] : Colors.grey[50]),
                          borderRadius: BorderRadius.circular(r.dp(20)),
                          border: Border.all(
                            color: isCorrect == false
                                ? Colors.red
                                : (isCorrect == true ? Colors.green : Colors.pink[100]!),
                            width: r.dp(3),
                          ),
                        ),
                        child: selectedWords.isEmpty
                            ? Center(
                                child: Text(
                                  lang == 'zh'
                                      ? "在这里点击词语..."
                                      : (lang == 'ms'
                                          ? "Tekan perkataan di bawah..."
                                          : "Tap words below..."),
                                  style: TextStyle(color: Colors.grey[400], fontSize: r.sp(15)),
                                ),
                              )
                            : Wrap(
                                alignment: WrapAlignment.center,
                                spacing: r.dp(10),
                                runSpacing: r.dp(10),
                                children: selectedWords.asMap().entries.map((e) {
                                  return ActionChip(
                                    label: Text(e.value,
                                        style: TextStyle(fontSize: r.sp(22))),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: r.dp(16), vertical: r.dp(12)),
                                    backgroundColor: Colors.pinkAccent,
                                    labelStyle: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
                                    onPressed: () {
                                      _resetIdleTimer();
                                      setState(() {
                                        selectedWords.removeAt(e.key);
                                        availableWords.add(e.value);
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                      ).animate(target: shakeTrigger > 0 ? 1 : 0,
                              onComplete: (c) => shakeTrigger = 0)
                          .shake(hz: 5, curve: Curves.easeInOut),

                      const Spacer(),

                      // Available word tiles
                      Wrap(
                        spacing: r.dp(14),
                        runSpacing: r.dp(14),
                        alignment: WrapAlignment.center,
                        children: availableWords.map((w) {
                          return GestureDetector(
                            onTap: () {
                              _resetIdleTimer();
                              unawaited(AudioManager().speak(w, lang));
                              setState(() {
                                availableWords.remove(w);
                                selectedWords.add(w);
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: r.dp(20), vertical: r.dp(14)),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(r.dp(16)),
                                border: Border.all(
                                    color: Colors.pinkAccent, width: r.dp(2.5)),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.pinkAccent.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app_rounded,
                                      size: r.icon(16), color: Colors.pinkAccent),
                                  SizedBox(width: r.dp(6)),
                                  Text(w,
                                      style: TextStyle(
                                          fontSize: r.sp(22),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ).animate(target: _showHint ? 1 : 0)
                          .shimmer(duration: 1.5.seconds, color: Colors.pink[100]),

                      const Spacer(),

                      // Check button
                      SizedBox(
                        width: r.dp(240),
                        height: r.dp(58),
                        child: ElevatedButton.icon(
                          onPressed: selectedWords.isEmpty
                              ? null
                              : () => _handleCheck(levelData, lang),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[200],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(r.dp(20))),
                            elevation: selectedWords.isEmpty ? 0 : 4,
                          ),
                          icon: Icon(Icons.check_circle_outline_rounded, size: r.icon(24)),
                          label: Text(
                            t['check']!,
                            style: TextStyle(
                                fontSize: r.sp(20), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ).animate(
                          target: (selectedWords.isNotEmpty && _showHint) ? 1 : 0)
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
