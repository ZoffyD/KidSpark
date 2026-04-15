import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/game_content.dart';
import '../game_services.dart';
import '../components/reward_animation.dart';
import '../utils/responsive.dart';
import '../main.dart';

class PuzzleGame extends StatefulWidget {
  final int level;
  final VoidCallback onBack;
  const PuzzleGame({super.key, required this.level, required this.onBack});

  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> {
  String? _droppedLabel;
  bool?   _isCorrect;
  bool    _isDragOver = false;
  int     _shakeTrigger = 0;
  bool    _showHint = false;
  Timer?  _idleTimer;

  int _wrongAttempts = 0;
  String? _encourageMsg;

  List<Map<String, dynamic>> _shuffledOptions = [];

  void _shuffleOptions() {
    final lang = KidSparkApp.languageNotifier.value;
    final levelData = GameContent.problemLevels[lang]![widget.level]
                   ?? GameContent.problemLevels[lang]![1]!;
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
    if (!mounted) return;
    _shuffleOptions();
    setState(() {
      _droppedLabel = null;
      _isCorrect = null;
      _isDragOver = false;
      _encourageMsg = null;
    });
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (mounted) setState(() => _showHint = false);
    _idleTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _droppedLabel == null) setState(() => _showHint = true);
    });
  }

  String _getEncouragement(String lang) {
    switch (lang) {
      case 'ms': return "Hampir! Cuba lagi!";
      case 'zh': return "差一点！再试试！";
      default:   return "Almost there! Try again!";
    }
  }

  void _handleDrop(Map<String, dynamic> option, Map<String, dynamic> levelData, String lang) {
    if (!mounted) return;

    final bool correct = option['correct'] as bool;
    setState(() {
      _droppedLabel = option['label'] as String;
      _isCorrect    = correct;
      _isDragOver   = false;
    });

    _resetIdleTimer();
    HapticFeedback.mediumImpact();

    if (correct) {
      unawaited(AudioManager().playSfx('correct.mp3'));
      setState(() => _encourageMsg = null);
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) unawaited(AudioManager().speak(levelData['name'] as String, lang));
      });

      final stars = ProgressService.calculateStars(_wrongAttempts);
      unawaited(ProgressService().unlockLevel('problem', widget.level + 1));
      unawaited(ProgressService().saveStars('problem', widget.level, stars));

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dCtx) => RewardDialog(
            starsEarned: stars,
            lang: lang,
            onContinue: () {
              Navigator.of(dCtx, rootNavigator: true).pop();
              widget.onBack();
            },
          ),
        );
      });
    } else {
      _wrongAttempts++;
      setState(() {
        _shakeTrigger++;
        _encourageMsg = _getEncouragement(lang);
      });
      HapticFeedback.vibrate();
      unawaited(AudioManager().playSfx('wrong.mp3'));

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() { _droppedLabel = null; _isCorrect = null; });
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
      builder: (context, lang, _) {
        final t         = GameContent.translations[lang]!;
        final levelData = GameContent.problemLevels[lang]![widget.level]
                       ?? GameContent.problemLevels[lang]![1]!;

        return Material(
          color: const Color(0xFFECFDF5),
          child: Row(
            children: [

              // LEFT — image + question + drop zone
              Expanded(
                flex: 5,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(r.dp(12), r.dp(10), r.dp(8), r.dp(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // Title + speaker
                      SizedBox(
                        height: r.dp(44),
                        child: Row(children: [
                          Expanded(
                            child: Text(
                              t['problemSolving'] ?? "Logic",
                              style: TextStyle(fontSize: r.sp(18), fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Speaker button
                          Container(
                            decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.volume_up_rounded, color: Colors.green, size: r.icon(24)),
                              onPressed: () {
                                _resetIdleTimer();
                                unawaited(AudioManager().speak(levelData['name'] as String, lang));
                              },
                            ),
                          ).animate(target: _showHint ? 1 : 0)
                              .shimmer(duration: 1.5.seconds, color: Colors.white),
                        ]),
                      ),
                      SizedBox(height: r.dp(6)),

                      // Big question image
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(r.dp(22)),
                          child: Image.asset(
                            levelData['questionImage'] as String,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[100],
                              child: Icon(Icons.image, size: r.icon(60), color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: r.dp(10)),

                      // Question text
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: r.dp(14), vertical: r.dp(10)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(r.dp(16)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                        ),
                        child: Text(
                          levelData['question'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: r.sp(17), fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                      SizedBox(height: r.dp(8)),

                      Center(child: _buildAttemptIndicator(r)),
                      SizedBox(height: r.dp(8)),

                      // Drop zone
                      _buildDropZone(levelData, lang, r),
                    ],
                  ),
                ),
              ),

              // RIGHT — draggable tiles
              Expanded(
                flex: 5,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(r.dp(4), r.dp(10), r.dp(12), r.dp(12)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      if (_encourageMsg != null)
                        Text(
                          _encourageMsg!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: r.sp(15),
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),

                      SizedBox(height: r.dp(8)),

                      // Draggable tiles
                      Wrap(
                        spacing: r.dp(16),
                        runSpacing: r.dp(16),
                        alignment: WrapAlignment.center,
                        children: List.generate(_shuffledOptions.length, (i) {
                          final opt    = _shuffledOptions[i];
                          final placed = _droppedLabel == opt['label'] && _isCorrect == true;
                          return _buildDraggableOption(opt, placed, lang, r);
                        }),
                      ),
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

  Widget _buildDropZone(Map<String, dynamic> levelData, String lang, Responsive r) {
    final bool isEmpty = _droppedLabel == null;
    final bool correct = _isCorrect == true;

    Color borderColor = isEmpty
        ? (_isDragOver ? Colors.green : Colors.green[300]!)
        : (correct ? Colors.green : Colors.red);
    Color bgColor = isEmpty
        ? (_isDragOver ? Colors.green[50]! : Colors.grey[50]!)
        : (correct ? Colors.green[50]! : Colors.red[50]!);

    Widget innerContent;

    if (isEmpty) {
      final dropText = lang == 'zh' ? '放这里' : (lang == 'ms' ? 'Letak sini' : 'Drop here');
      innerContent = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isDragOver ? Icons.check_circle_outline_rounded : Icons.arrow_downward_rounded,
            color: _isDragOver ? Colors.green : Colors.green[300],
            size: r.icon(28),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -4, end: 4, duration: 800.ms, curve: Curves.easeInOut),
          SizedBox(width: r.dp(8)),
          Text(
            dropText,
            style: TextStyle(
              fontSize: r.sp(15), fontWeight: FontWeight.bold,
              color: _isDragOver ? Colors.green : Colors.grey[400],
            ),
          ),
        ],
      );
    } else if (correct) {
      innerContent = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(r.dp(12)),
            child: Image.asset(
              (levelData['options'] as List)
                  .firstWhere((o) => (o as Map)['correct'] == true)['image'] as String,
              height: r.dp(70), width: r.dp(90), fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ).animate().scale(begin: const Offset(0.4, 0.4), end: const Offset(1, 1),
              duration: 400.ms, curve: Curves.elasticOut),
          SizedBox(width: r.dp(12)),
          Flexible(
            child: Text(
              _droppedLabel!,
              style: TextStyle(fontSize: r.sp(18), fontWeight: FontWeight.bold, color: Colors.green[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: r.dp(8)),
          Icon(Icons.check_circle_rounded, color: Colors.green, size: r.icon(28))
              .animate().scale(duration: 300.ms, curve: Curves.elasticOut),
        ],
      );
    } else {
      innerContent = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("❌", style: TextStyle(fontSize: r.sp(24))),
          SizedBox(width: r.dp(10)),
          Text(
            lang == 'zh' ? "再试试！" : (lang == 'ms' ? "Cuba lagi!" : "Try again!"),
            style: TextStyle(fontSize: r.sp(15), fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ],
      );
    }

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isDragOver = true);
        });
        return true;
      },
      onLeave: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isDragOver = false);
        });
      },
      onAcceptWithDetails: (details) => _handleDrop(details.data, levelData, lang),
      builder: (context, _, __) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: r.dp(90),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(r.dp(18)),
            border: Border.all(color: borderColor, width: _isDragOver ? 3 : 2),
            boxShadow: _isDragOver
                ? [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)]
                : [],
          ),
          child: Center(child: innerContent),
        ).animate(target: _shakeTrigger > 0 ? 1 : 0, onComplete: (c) => _shakeTrigger = 0)
            .shake(hz: 5, offset: const Offset(8, 0));
      },
    );
  }

  Widget _buildDraggableOption(Map<String, dynamic> opt, bool placedCorrectly, String lang, Responsive r) {
    if (placedCorrectly) {
      return _optionTile(opt, isDragging: false, disabled: true, r: r);
    }

    return Draggable<Map<String, dynamic>>(
      data: opt,
      onDragStarted: () {
        _resetIdleTimer();
        HapticFeedback.selectionClick();
        unawaited(AudioManager().speak(opt['label'] as String, lang));
      },
      feedback: Material(
        color: Colors.transparent,
        child: _optionTile(opt, isDragging: true, disabled: false, r: r),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: _optionTile(opt, isDragging: false, disabled: true, r: r),
      ),
      child: _showHint
          ? _optionTile(opt, isDragging: false, disabled: false, r: r)
              .animate().shimmer(duration: 1.5.seconds, color: Colors.green[100])
          : _optionTile(opt, isDragging: false, disabled: false, r: r),
    );
  }

  Widget _optionTile(Map<String, dynamic> opt, {required bool isDragging, required bool disabled, required Responsive r}) {
    final double tileSize = r.dp(140);

    return Container(
      width: tileSize,
      height: tileSize,
      decoration: BoxDecoration(
        color: disabled ? Colors.grey[100] : (isDragging ? Colors.green[50] : Colors.white),
        borderRadius: BorderRadius.circular(r.dp(20)),
        border: Border.all(
          color: disabled ? Colors.grey[300]!
              : (isDragging ? Colors.green : Colors.green[300]!),
          width: isDragging ? 3 : 2,
        ),
        boxShadow: isDragging
            ? [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))]
            : [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(r.dp(18))),
              child: Image.asset(
                opt['image'] as String,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.image, color: Colors.grey, size: r.icon(36)),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: r.dp(6), horizontal: r.dp(6)),
            decoration: BoxDecoration(
              color: disabled ? Colors.grey[200] : (isDragging ? Colors.green[100] : Colors.green[50]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(r.dp(18))),
            ),
            child: Text(
              opt['label'] as String,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: r.sp(13),
                color: disabled ? Colors.grey[500] : Colors.green[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
