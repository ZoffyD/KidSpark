import 'package:flutter/material.dart';
import '../game_services.dart';
import '../utils/responsive.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioManager audio = AudioManager();

  String _label(String lang, String en, String ms, String zh) {
    if (lang == 'zh') return zh;
    if (lang == 'ms') return ms;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return ValueListenableBuilder<String>(
      valueListenable: KidSparkApp.languageNotifier,
      builder: (context, lang, child) {
        const Color themeColor = Color(0xFFF3E5F5);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [themeColor.withOpacity(0.2), Colors.white],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: r.dp(24), vertical: r.dp(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label(lang, "Settings", "Tetapan", "设置"),
                  style: TextStyle(
                    fontSize: r.sp(24),
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                SizedBox(height: r.dp(16)),

                // Sound toggles
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactCard(
                        _label(lang, "Background Music", "Muzik Latar", "背景音乐"),
                        Icons.music_note_rounded,
                        audio.isMusicOn,
                        Colors.purpleAccent,
                        (v) async {
                          await audio.toggleMusic(v);
                          setState(() {});
                        },
                        r,
                      ),
                    ),
                    SizedBox(width: r.dp(12)),
                    Expanded(
                      child: _buildCompactCard(
                        _label(lang, "Sound Effects", "Efek Bunyi", "音效"),
                        Icons.volume_up_rounded,
                        audio.isSfxOn,
                        Colors.blueAccent,
                        (v) {
                          audio.isSfxOn = v;
                          setState(() {});
                        },
                        r,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.dp(16)),
                const Divider(),
                SizedBox(height: r.dp(8)),

                Text(
                  _label(lang, "Credits", "Kredit", "版权信息"),
                  style: TextStyle(fontSize: r.sp(14), fontWeight: FontWeight.bold),
                ),
                SizedBox(height: r.dp(8)),
                Container(
                  padding: EdgeInsets.all(r.dp(10)),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(r.dp(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Music credit row
                      Row(children: [
                        Icon(Icons.music_note_rounded, size: r.icon(14), color: Colors.purple[300]),
                        SizedBox(width: r.dp(6)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Momo Island by Piki  •  freetouse.com/music",
                                style: TextStyle(fontSize: r.sp(10), fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _label(lang,
                                  "Copyright Free Music",
                                  "Muzik Bebas Hak Cipta",
                                  "免版权音乐"),
                                style: TextStyle(fontSize: r.sp(9), color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      SizedBox(height: r.dp(8)),
                      const Divider(height: 1),
                      SizedBox(height: r.dp(8)),
                      // Image credit row
                      Row(children: [
                        Icon(Icons.image_rounded, size: r.icon(14), color: Colors.blue[300]),
                        SizedBox(width: r.dp(6)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Images designed using Canva  •  canva.com",
                                style: TextStyle(fontSize: r.sp(10), fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _label(lang,
                                  "Canva Content License Agreement",
                                  "Perjanjian Lesen Kandungan Canva",
                                  "Canva内容许可协议"),
                                style: TextStyle(fontSize: r.sp(9), color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactCard(
    String title,
    IconData icon,
    bool value,
    Color color,
    Function(bool) onChanged,
    Responsive r,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: r.dp(12), horizontal: r.dp(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.dp(20)),
        border: Border.all(
          color: value ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: r.icon(22)),
          SizedBox(height: r.dp(6)),
          Text(title,
              style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          Switch(value: value, onChanged: onChanged, activeColor: color),
        ],
      ),
    );
  }
}
