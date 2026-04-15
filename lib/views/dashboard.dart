import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../game_services.dart';
import '../utils/responsive.dart';
import 'settings_screen.dart';
import 'word_builder_game.dart';
import 'emotional_game.dart';
import 'puzzle_game.dart';
import '../data/game_content.dart';
import '../main.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});
  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  int? _activeLevel;
  final AudioManager audioManager = AudioManager();

  int wordUnlocked = 1;
  int emotionUnlocked = 1;
  int problemUnlocked = 1;

  Map<int, int> wordStars = {};
  Map<int, int> emotionStars = {};
  Map<int, int> problemStars = {};

  static const List<String> wordImages = [
    'assets/images/nasilemak.png',
    'assets/images/wau.png',
    'assets/images/kltower.png',
    'assets/images/tiger.png',
    'assets/images/hibiscus.png',
  ];
  static const List<String> feelingImages = [
    'assets/images/birthday.png',
    'assets/images/brokentoy.png',
    'assets/images/storm.png',
    'assets/images/satay.png',
    'assets/images/bedtime.png',
  ];
  static const List<String> puzzleImages = [
    'assets/images/nasilemak.png',
    'assets/images/wau.png',
    'assets/images/satay.png',
    'assets/images/flag.png',
    'assets/images/hibiscus.png',
  ];

  @override
  void initState() {
    super.initState();
    audioManager.playBackgroundMusic('map.mp3');
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        wordUnlocked = prefs.getInt('kidspark_word_unlocked') ?? 1;
        emotionUnlocked = prefs.getInt('kidspark_emotional_unlocked') ?? 1;
        problemUnlocked = prefs.getInt('kidspark_problem_unlocked') ?? 1;

        for (int i = 1; i <= 5; i++) {
          wordStars[i] = prefs.getInt('kidspark_word_stars_$i') ?? 0;
          emotionStars[i] = prefs.getInt('kidspark_emotional_stars_$i') ?? 0;
          problemStars[i] = prefs.getInt('kidspark_problem_stars_$i') ?? 0;
        }
      });
    }
  }

  void _exitToMap() {
    setState(() => _activeLevel = null);
    _loadProgress();
  }

  void _showInstructionDialog(
      BuildContext context, String lang, String gameType) {
    final r = Responsive(context);

    final instructions = {
      'en': {
        'word':      "Tap the words to spell the name!",
        'emotional': "Look at the picture.\nHow does this person feel?",
        'problem':   "Drag the correct answer\ninto the box!",
      },
      'ms': {
        'word':      "Tekan perkataan untuk eja nama!",
        'emotional': "Lihat gambar.\nApa perasaan orang ini?",
        'problem':   "Seret jawapan yang betul\nke dalam kotak!",
      },
      'zh': {
        'word':      "点击词语来拼写名字！",
        'emotional': "看看图片。\n这个人感觉怎样？",
        'problem':   "把正确的答案\n拖进方框里！",
      },
    };

    final titles = {
      'en': {'word': "Word Game", 'emotional': "Feelings Game", 'problem': "Logic Game"},
      'ms': {'word': "Permainan Kata", 'emotional': "Permainan Perasaan", 'problem': "Permainan Logik"},
      'zh': {'word': "词语游戏", 'emotional': "心情游戏", 'problem': "逻辑游戏"},
    };

    final emojis = {'word': "📝", 'emotional': "😊", 'problem': "🧩"};
    final startLabel = lang == 'zh' ? "开始！" : (lang == 'ms' ? "Mula!" : "Let's Go!");

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.dp(28))),
        child: SizedBox(
          width: r.dp(320),
          child: Padding(
            padding: EdgeInsets.all(r.dp(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emojis[gameType] ?? "🎮",
                  style: TextStyle(fontSize: r.sp(48)),
                ),
                SizedBox(height: r.dp(12)),
                Text(
                  titles[lang]?[gameType] ?? titles['en']![gameType]!,
                  style: TextStyle(
                    fontSize: r.sp(22),
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                SizedBox(height: r.dp(16)),
                Text(
                  instructions[lang]?[gameType] ?? instructions['en']![gameType]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: r.sp(17), fontWeight: FontWeight.w600, height: 1.5),
                ),
                SizedBox(height: r.dp(24)),
                SizedBox(
                  width: double.infinity,
                  height: r.dp(52),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(r.dp(16))),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(startLabel,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: r.sp(18),
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return ValueListenableBuilder<String>(
      valueListenable: KidSparkApp.languageNotifier,
      builder: (context, lang, child) {
        final t = GameContent.translations[lang]!;

        final List<Map<String, dynamic>> menuItems = [
          {
            'icon':   Icons.menu_book_rounded,
            'label':  t['wordBuilder']!,
            'color':  const Color(0xFFFFE5F1),
            'accent': Colors.pinkAccent,
          },
          {
            'icon':   Icons.favorite_border_rounded,
            'label':  t['emotional']!,
            'color':  const Color(0xFFE3F2FD),
            'accent': Colors.blueAccent,
          },
          {
            'icon':   Icons.lightbulb_outline_rounded,
            'label':  t['problemSolving']!,
            'color':  const Color(0xFFE0F7E9),
            'accent': Colors.greenAccent,
          },
          {
            'icon':   Icons.settings_outlined,
            'label':  t['settings'] ?? 'Settings',
            'color':  const Color(0xFFF3E5F5),
            'accent': Colors.purpleAccent,
          },
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Row(
            children: [
              // ── Sidebar ───────────────────────────────────────────────
              Container(
                width: r.dp(100),
                margin: EdgeInsets.all(r.dp(10)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(r.dp(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: r.dp(6)),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(menuItems.length, (i) {
                            return _buildSidebarItem(menuItems[i], _selectedIndex == i, i, r);
                          }),
                        ),
                      ),
                    ),
                    SizedBox(height: r.dp(2)),
                    _buildLanguageToggle(lang, r),
                    SizedBox(height: r.dp(6)),
                  ],
                ),
              ),

              // ── Main content ──────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, r.dp(10), r.dp(10), r.dp(10)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(r.dp(28)),
                      boxShadow: [
                        BoxShadow(
                          color: (menuItems[_selectedIndex]['accent'] as Color)
                              .withOpacity(0.1),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(r.dp(28)),
                      child: _buildContent(lang, t, menuItems[_selectedIndex]['accent']),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarItem(Map item, bool isSelected, int index, Responsive r) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        unawaited(audioManager.playSfx('click.mp3'));
        setState(() { _selectedIndex = index; _activeLevel = null; });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: r.dp(80),
        margin: EdgeInsets.symmetric(vertical: r.dp(2)),
        padding: EdgeInsets.symmetric(vertical: r.dp(7), horizontal: r.dp(4)),
        decoration: BoxDecoration(
          color: isSelected ? (item['color'] as Color) : Colors.transparent,
          borderRadius: BorderRadius.circular(r.dp(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item['icon'],
              size: r.icon(26),
              color: isSelected
                  ? (item['accent'] as Color).withOpacity(0.9)
                  : Colors.grey[400],
            ),
            SizedBox(height: r.dp(3)),
            Text(
              item['label'],
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: r.sp(9),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                color: isSelected ? Colors.black87 : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(String currentLang, Responsive r) {
    final langs = [
      {'code': 'en', 'label': 'EN',  'flag': '🇬🇧', 'color': Colors.blueAccent},
      {'code': 'ms', 'label': 'BM',  'flag': '🇲🇾', 'color': Colors.orangeAccent},
      {'code': 'zh', 'label': '中',  'flag': '🔤',  'color': Colors.redAccent},
    ];
    final titleMap = {'en': 'Language', 'ms': 'Bahasa', 'zh': '语言'};

    return Column(
      children: [
        Text(
          titleMap[currentLang] ?? 'Language',
          style: TextStyle(fontSize: r.sp(9), fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        SizedBox(height: r.dp(4)),
        Container(
          width: r.dp(80),
          padding: EdgeInsets.all(r.dp(3)),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(r.dp(18)),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: langs.map((lang) {
              final isActive = currentLang == lang['code'];
              final color = lang['color'] as Color;
              return GestureDetector(
                onTap: () async {
                  if (currentLang == lang['code']) return;
                  HapticFeedback.lightImpact();
                  unawaited(audioManager.playSfx('click.mp3'));
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('kidspark_language', lang['code'] as String);
                  KidSparkApp.languageNotifier.value = lang['code'] as String;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(vertical: r.dp(1)),
                  padding: EdgeInsets.symmetric(vertical: r.dp(4), horizontal: r.dp(4)),
                  decoration: BoxDecoration(
                    color: isActive ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(r.dp(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lang['flag'] as String,
                        style: TextStyle(fontSize: r.sp(12)),
                      ),
                      SizedBox(width: r.dp(3)),
                      Text(
                        lang['label'] as String,
                        style: TextStyle(
                          fontSize: r.sp(10),
                          fontWeight: FontWeight.w900,
                          color: isActive ? Colors.white : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(String lang, Map<String, String> t, Color accentColor) {
    if (_activeLevel != null) {
      if (_selectedIndex == 0) return WordBuilderGame(level: _activeLevel!, onBack: _exitToMap);
      if (_selectedIndex == 1) return EmotionalGame(level: _activeLevel!, onBack: _exitToMap);
      if (_selectedIndex == 2) return PuzzleGame(level: _activeLevel!, onBack: _exitToMap);
    }

    switch (_selectedIndex) {
      case 0:
        return ImageLevelMap(
          title: t['wordBuilder']!,
          unlockedLevel: wordUnlocked,
          themeColor: accentColor,
          levelImages: wordImages,
          levelStars: wordStars,
          onLevelSelect: (lv) {
            _showInstructionDialog(context, lang, 'word');
            setState(() => _activeLevel = lv);
          },
        );
      case 1:
        return ImageLevelMap(
          title: t['emotional']!,
          unlockedLevel: emotionUnlocked,
          themeColor: accentColor,
          levelImages: feelingImages,
          levelStars: emotionStars,
          onLevelSelect: (lv) {
            _showInstructionDialog(context, lang, 'emotional');
            setState(() => _activeLevel = lv);
          },
        );
      case 2:
        return ImageLevelMap(
          title: t['problemSolving']!,
          unlockedLevel: problemUnlocked,
          themeColor: accentColor,
          levelImages: puzzleImages,
          levelStars: problemStars,
          onLevelSelect: (lv) {
            _showInstructionDialog(context, lang, 'problem');
            setState(() => _activeLevel = lv);
          },
        );
      case 3:
        return const SettingsScreen();
      default:
        return const SizedBox();
    }
  }
}

class ImageLevelMap extends StatelessWidget {
  final String title;
  final int unlockedLevel;
  final Color themeColor;
  final List<String> levelImages;
  final Map<int, int> levelStars;
  final Function(int) onLevelSelect;

  const ImageLevelMap({
    super.key,
    required this.title,
    required this.unlockedLevel,
    required this.themeColor,
    required this.levelImages,
    required this.levelStars,
    required this.onLevelSelect,
  });

  int get _totalStars {
    int total = 0;
    for (final entry in levelStars.entries) {
      total += entry.value;
    }
    return total;
  }

  int get _maxStars => levelImages.length * 3;

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final double itemSpacing = r.dp(170);
    final double amplitude   = r.dp(65);
    final double nodeSize    = r.dp(90);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [themeColor.withOpacity(0.15), Colors.white],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: r.dp(16), bottom: r.dp(4), left: r.dp(20), right: r.dp(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: r.sp(24),
                    fontWeight: FontWeight.w900,
                    color: themeColor.withOpacity(0.85),
                  ),
                ),
                SizedBox(width: r.dp(16)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: r.dp(12), vertical: r.dp(6)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D3D3D),
                    borderRadius: BorderRadius.circular(r.dp(20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: r.icon(18), color: Colors.amber),
                      SizedBox(width: r.dp(4)),
                      Text(
                        "$_totalStars / $_maxStars",
                        style: TextStyle(
                          fontSize: r.sp(14),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final centerY = constraints.maxHeight / 2;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: levelImages.length * itemSpacing + r.dp(180),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: SinePathPainter(
                              totalLevels:   levelImages.length,
                              itemSpacing:   itemSpacing,
                              amplitude:     amplitude,
                              centerY:       centerY,
                              unlockedLevel: unlockedLevel,
                              color:         themeColor,
                              strokeWidth:   r.dp(8),
                            ),
                          ),
                        ),
                        ...List.generate(levelImages.length, (index) {
                          final level    = index + 1;
                          final isLocked = level > unlockedLevel;
                          final x        = index * itemSpacing + r.dp(70);
                          final y        = centerY + sin(index * 1.2) * amplitude - nodeSize * 0.72;
                          final stars    = levelStars[level] ?? 0;
                          return Positioned(
                            left: x,
                            top:  y,
                            child: GestureDetector(
                              onTap: isLocked ? null : () => onLevelSelect(level),
                              child: _buildNode(level, isLocked, levelImages[index], stars, r),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(int level, bool locked, String imagePath, int stars, Responsive r) {
    final double nodeSize = r.dp(90);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: nodeSize,
          height: nodeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: locked ? Colors.grey[300]! : themeColor,
              width: r.dp(5),
            ),
            boxShadow: [
              BoxShadow(
                color: locked
                    ? Colors.transparent
                    : themeColor.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipOval(
            child: locked
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                              Colors.grey, BlendMode.saturation),
                          child: Image.asset(imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.grey[200])),
                        ),
                      ),
                      Container(color: Colors.black.withOpacity(0.35)),
                      Center(
                        child: Icon(Icons.lock_rounded,
                            color: Colors.white, size: r.icon(30)),
                      ),
                    ],
                  )
                : Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[200],
                            child: Icon(Icons.image,
                                color: Colors.grey[400], size: r.icon(32))),
                  ),
          ),
        ),
        SizedBox(height: r.dp(4)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: r.dp(8), vertical: r.dp(2)),
          decoration: BoxDecoration(
            color: locked ? Colors.grey[300] : themeColor,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$level',
            style: TextStyle(
                color: Colors.white,
                fontSize: r.sp(11),
                fontWeight: FontWeight.bold),
          ),
        ),
        if (!locked)
          Padding(
            padding: EdgeInsets.only(top: r.dp(4)),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: r.dp(6), vertical: r.dp(3)),
              decoration: BoxDecoration(
                color: const Color(0xFF3D3D3D),
                borderRadius: BorderRadius.circular(r.dp(10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Icon(
                    i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                    size: r.icon(16),
                    color: i < stars ? Colors.amber : Colors.grey[600],
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }
}


class SinePathPainter extends CustomPainter {
  final int totalLevels;
  final double itemSpacing;
  final double amplitude;
  final double centerY;
  final int unlockedLevel;
  final Color color;
  final double strokeWidth;

  SinePathPainter({
    required this.totalLevels,
    required this.itemSpacing,
    required this.amplitude,
    required this.centerY,
    required this.unlockedLevel,
    required this.color,
    this.strokeWidth = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()
      ..color = color.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startX = itemSpacing * 0.41 + itemSpacing * 0.24;
    final path = Path()..moveTo(startX, centerY);
    for (double i = 0; i < totalLevels - 1; i += 0.05) {
      path.lineTo(i * itemSpacing + startX, centerY + sin(i * 1.2) * amplitude);
    }
    canvas.drawPath(path, dimPaint);

    final activePath = Path()..moveTo(startX, centerY);
    for (double i = 0; i < unlockedLevel - 1; i += 0.05) {
      activePath.lineTo(i * itemSpacing + startX, centerY + sin(i * 1.2) * amplitude);
    }
    canvas.drawPath(activePath, activePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
