class GameContent {

  static Map<String, Map<String, String>> translations = {
    'en': {
      'wordBuilder':    "Words",
      'emotional':      "Feelings",
      'problemSolving': "Logic",
      'settings':       "Settings",
      'level':          "Level",
      'check':          "Check",
      'buildWord':      "Build the word:",
      'howFeel':        "How do they feel?",
      'whatIsThis':     "What is this? 🤔",
    },
    'ms': {
      'wordBuilder':    "Perkataan",
      'emotional':      "Perasaan",
      'problemSolving': "Logik",
      'settings':       "Tetapan",
      'level':          "Tahap",
      'check':          "Semak",
      'buildWord':      "Bina perkataan:",
      'howFeel':        "Apa perasaan dia?",
      'whatIsThis':     "Apakah ini? 🤔",
    },
    'zh': {
      'wordBuilder':    "词语",
      'emotional':      "心情",
      'problemSolving': "逻辑",
      'settings':       "设置",
      'level':          "关卡",
      'check':          "检查",
      'buildWord':      "拼词语:",
      'howFeel':        "他/她感觉如何？",
      'whatIsThis':     "这是什么？🤔",
    },
  };

  // ── Word Builder ──────────────────────────────────────────────────────────
 
  static Map<String, Map<int, dynamic>> wordBuilderLevels = {
    'en': {
      1: {'flag': '🍚', 'greeting': 'Coconut Rice',   'words': ['Coconut', 'Rice'],   'correctSentence': 'Coconut Rice',  'image': 'assets/images/nasilemak.png'},
      2: {'flag': '🪁', 'greeting': 'Moon Kite',     'words': ['Moon',    'Kite'],   'correctSentence': 'Moon Kite',     'image': 'assets/images/wau.png'},
      3: {'flag': '🗼', 'greeting': 'KL Tower',      'words': ['KL',      'Tower'],  'correctSentence': 'KL Tower',      'image': 'assets/images/kltower.png'},
      4: {'flag': '🐯', 'greeting': 'Malayan Tiger', 'words': ['Malayan', 'Tiger'],  'correctSentence': 'Malayan Tiger', 'image': 'assets/images/tiger.png'},
      5: {'flag': '🌸', 'greeting': 'Hibiscus Flower',    'words': ['Hibiscus',   'Flower'],   'correctSentence': 'Hibiscus Flower',    'image': 'assets/images/hibiscus.png'},
    },
    'ms': {
      1: {'flag': '🍚', 'greeting': 'Nasi Lemak',     'words': ['Nasi',    'Lemak'],  'correctSentence': 'Nasi Lemak',     'image': 'assets/images/nasilemak.png'},
      2: {'flag': '🪁', 'greeting': 'Wau Bulan',      'words': ['Wau',     'Bulan'],  'correctSentence': 'Wau Bulan',      'image': 'assets/images/wau.png'},
      3: {'flag': '🗼', 'greeting': 'Menara KL',      'words': ['Menara',  'KL'],     'correctSentence': 'Menara KL',      'image': 'assets/images/kltower.png'},
      4: {'flag': '🐯', 'greeting': 'Harimau Malaya', 'words': ['Harimau', 'Malaya'], 'correctSentence': 'Harimau Malaya', 'image': 'assets/images/tiger.png'},
      5: {'flag': '🌸', 'greeting': 'Bunga Raya',     'words': ['Bunga',   'Raya'],   'correctSentence': 'Bunga Raya',     'image': 'assets/images/hibiscus.png'},
    },
    'zh': {
      1: {'flag': '🍚', 'greeting': '椰浆饭',   'words': ['椰浆',   '饭'],  'correctSentence': '椰浆 饭',   'image': 'assets/images/nasilemak.png'},
      2: {'flag': '🪁', 'greeting': '月亮风筝', 'words': ['月亮',   '风筝'], 'correctSentence': '月亮 风筝', 'image': 'assets/images/wau.png'},
      3: {'flag': '🗼', 'greeting': '吉隆坡塔', 'words': ['吉隆坡', '塔'],  'correctSentence': '吉隆坡 塔', 'image': 'assets/images/kltower.png'},
      4: {'flag': '🐯', 'greeting': '马来亚虎', 'words': ['马来亚', '虎'],  'correctSentence': '马来亚 虎', 'image': 'assets/images/tiger.png'},
      5: {'flag': '🌸', 'greeting': '大红花',   'words': ['大红',   '花'],  'correctSentence': '大红 花',   'image': 'assets/images/hibiscus.png'},
    },
  };

  // ── Emotional levels — 4 options each ────────────────────────────────────
  static Map<String, Map<int, dynamic>> emotionalLevels = {
    'en': {
      1: {
        'scenario': 'Birthday present!',
        'image': 'assets/images/birthday.png',
        'options': [
          {'emoji': '😃', 'label': 'Happy',   'correct': true},
          {'emoji': '😢', 'label': 'Sad',     'correct': false},
          {'emoji': '😠', 'label': 'Angry',   'correct': false},
          {'emoji': '😴', 'label': 'Sleepy',  'correct': false},
        ],
      },
      2: {
        'scenario': 'Lost my toy.',
        'image': 'assets/images/brokentoy.png',
        'options': [
          {'emoji': '😢', 'label': 'Sad',     'correct': true},
          {'emoji': '😃', 'label': 'Happy',   'correct': false},
          {'emoji': '😠', 'label': 'Angry',   'correct': false},
          {'emoji': '😋', 'label': 'Yummy',   'correct': false},
        ],
      },
      3: {
        'scenario': 'Loud thunder!',
        'image': 'assets/images/storm.png',
        'options': [
          {'emoji': '😱', 'label': 'Scared',  'correct': true},
          {'emoji': '😴', 'label': 'Sleepy',  'correct': false},
          {'emoji': '😃', 'label': 'Happy',   'correct': false},
          {'emoji': '😋', 'label': 'Yummy',   'correct': false},
        ],
      },
      4: {
        'scenario': 'Eating Satay!',
        'image': 'assets/images/satay.png',
        'options': [
          {'emoji': '😋', 'label': 'Yummy',   'correct': true},
          {'emoji': '😱', 'label': 'Scared',  'correct': false},
          {'emoji': '😢', 'label': 'Sad',     'correct': false},
          {'emoji': '😠', 'label': 'Angry',   'correct': false},
        ],
      },
      5: {
        'scenario': 'Time for bed.',
        'image': 'assets/images/bedtime.png',
        'options': [
          {'emoji': '😴', 'label': 'Sleepy',  'correct': true},
          {'emoji': '😃', 'label': 'Happy',   'correct': false},
          {'emoji': '😱', 'label': 'Scared',  'correct': false},
          {'emoji': '😠', 'label': 'Angry',   'correct': false},
        ],
      },
    },
    'ms': {
      1: {
        'scenario': 'Hadiah hari jadi!',
        'image': 'assets/images/birthday.png',
        'options': [
          {'emoji': '😃', 'label': 'Gembira',    'correct': true},
          {'emoji': '😢', 'label': 'Sedih',      'correct': false},
          {'emoji': '😠', 'label': 'Marah',      'correct': false},
          {'emoji': '😴', 'label': 'Mengantuk',  'correct': false},
        ],
      },
      2: {
        'scenario': 'Mainan hilang.',
        'image': 'assets/images/brokentoy.png',
        'options': [
          {'emoji': '😢', 'label': 'Sedih',      'correct': true},
          {'emoji': '😃', 'label': 'Gembira',    'correct': false},
          {'emoji': '😠', 'label': 'Marah',      'correct': false},
          {'emoji': '😋', 'label': 'Sedap',      'correct': false},
        ],
      },
      3: {
        'scenario': 'Bunyi guruh!',
        'image': 'assets/images/storm.png',
        'options': [
          {'emoji': '😱', 'label': 'Takut',      'correct': true},
          {'emoji': '😴', 'label': 'Mengantuk',  'correct': false},
          {'emoji': '😃', 'label': 'Gembira',    'correct': false},
          {'emoji': '😋', 'label': 'Sedap',      'correct': false},
        ],
      },
      4: {
        'scenario': 'Makan Satay!',
        'image': 'assets/images/satay.png',
        'options': [
          {'emoji': '😋', 'label': 'Sedap',      'correct': true},
          {'emoji': '😱', 'label': 'Takut',      'correct': false},
          {'emoji': '😢', 'label': 'Sedih',      'correct': false},
          {'emoji': '😠', 'label': 'Marah',      'correct': false},
        ],
      },
      5: {
        'scenario': 'Masa tidur.',
        'image': 'assets/images/bedtime.png',
        'options': [
          {'emoji': '😴', 'label': 'Mengantuk',  'correct': true},
          {'emoji': '😃', 'label': 'Gembira',    'correct': false},
          {'emoji': '😱', 'label': 'Takut',      'correct': false},
          {'emoji': '😠', 'label': 'Marah',      'correct': false},
        ],
      },
    },
    'zh': {
      1: {
        'scenario': '收到生日礼物！',
        'image': 'assets/images/birthday.png',
        'options': [
          {'emoji': '😃', 'label': '开心', 'correct': true},
          {'emoji': '😢', 'label': '伤心', 'correct': false},
          {'emoji': '😠', 'label': '生气', 'correct': false},
          {'emoji': '😴', 'label': '想睡', 'correct': false},
        ],
      },
      2: {
        'scenario': '玩具丢了。',
        'image': 'assets/images/brokentoy.png',
        'options': [
          {'emoji': '😢', 'label': '伤心', 'correct': true},
          {'emoji': '😃', 'label': '开心', 'correct': false},
          {'emoji': '😠', 'label': '生气', 'correct': false},
          {'emoji': '😋', 'label': '好吃', 'correct': false},
        ],
      },
      3: {
        'scenario': '大雷声！',
        'image': 'assets/images/storm.png',
        'options': [
          {'emoji': '😱', 'label': '害怕', 'correct': true},
          {'emoji': '😴', 'label': '想睡', 'correct': false},
          {'emoji': '😃', 'label': '开心', 'correct': false},
          {'emoji': '😋', 'label': '好吃', 'correct': false},
        ],
      },
      4: {
        'scenario': '吃沙爹！',
        'image': 'assets/images/satay.png',
        'options': [
          {'emoji': '😋', 'label': '好吃', 'correct': true},
          {'emoji': '😱', 'label': '害怕', 'correct': false},
          {'emoji': '😢', 'label': '伤心', 'correct': false},
          {'emoji': '😠', 'label': '生气', 'correct': false},
        ],
      },
      5: {
        'scenario': '睡觉时间。',
        'image': 'assets/images/bedtime.png',
        'options': [
          {'emoji': '😴', 'label': '想睡', 'correct': true},
          {'emoji': '😃', 'label': '开心', 'correct': false},
          {'emoji': '😱', 'label': '害怕', 'correct': false},
          {'emoji': '😠', 'label': '生气', 'correct': false},
        ],
      },
    },
  };

  // ── Logic / Puzzle levels — 4 image-tile options each ────────────────────
  static Map<String, Map<int, dynamic>> problemLevels = {
    'en': {
      1: {
        'name':          'Coconut Rice',
        'questionImage': 'assets/images/nasilemak.png',
        'question':      'What food is this?',
        'options': [
          {'label': 'Coconut Rice','image': 'assets/images/nasilemak.png',  'correct': true},
          {'label': 'Flatbread',   'image': 'assets/images/roticanai.png',  'correct': false},
          {'label': 'Skewers',     'image': 'assets/images/satay.png',      'correct': false},
          {'label': 'Iced Milo',   'image': 'assets/images/miloais.png',    'correct': false},
        ],
      },
      2: {
        'name':          'Moon Kite',
        'questionImage': 'assets/images/wau.png',
        'question':      'What is this called?',
        'options': [
          {'label': 'Moon Kite',   'image': 'assets/images/wau.png',        'correct': true},
          {'label': 'KL Tower',    'image': 'assets/images/kltower.png',    'correct': false},
          {'label': 'Hibiscus',  'image': 'assets/images/hibiscus.png',   'correct': false},
          {'label': 'Skewers',       'image': 'assets/images/satay.png',      'correct': false},
        ],
      },
      3: {
        'name':          'Skewers',
        'questionImage': 'assets/images/satay.png',
        'question':      'What food is this?',
        'options': [
          {'label': 'Skewers',      'image': 'assets/images/satay.png',      'correct': true},
          {'label': 'Coconut Rice','image': 'assets/images/nasilemak.png',  'correct': false},
          {'label': 'Flatbread',   'image': 'assets/images/roticanai.png',  'correct': false},
          {'label': 'Iced Milo',   'image': 'assets/images/miloais.png',    'correct': false},
        ],
      },
      4: {
        'name':          'Jalur Gemilang',
        'questionImage': 'assets/images/flag.png',
        'question':      'What flag is this?',
        'options': [
          {'label': 'Malaysia Flag','image': 'assets/images/flag.png',      'correct': true},
          {'label': 'KL Tower',    'image': 'assets/images/kltower.png',    'correct': false},
          {'label': 'Moon Kite',   'image': 'assets/images/wau.png',        'correct': false},
          {'label': 'Hibiscus',  'image': 'assets/images/hibiscus.png',   'correct': false},
        ],
      },
      5: {
        'name':          'Hibiscus',
        'questionImage': 'assets/images/hibiscus.png',
        'question':      'What flower is this?',
        'options': [
          {'label': 'Hibiscus',  'image': 'assets/images/hibiscus.png',   'correct': true},
          {'label': 'Skewers',       'image': 'assets/images/satay.png',      'correct': false},
          {'label': 'Moon Kite',   'image': 'assets/images/wau.png',        'correct': false},
          {'label': 'Coconut Rice','image': 'assets/images/nasilemak.png',  'correct': false},
        ],
      },
    },

    'ms': {
      1: {
        'name':          'Nasi Lemak',
        'questionImage': 'assets/images/nasilemak.png',
        'question':      'Apakah makanan ini?',
        'options': [
          {'label': 'Nasi Lemak',  'image': 'assets/images/nasilemak.png',  'correct': true},
          {'label': 'Roti Canai',  'image': 'assets/images/roticanai.png',  'correct': false},
          {'label': 'Satay',       'image': 'assets/images/satay.png',      'correct': false},
          {'label': 'Milo Ais',    'image': 'assets/images/miloais.png',    'correct': false},
        ],
      },
      2: {
        'name':          'Wau Bulan',
        'questionImage': 'assets/images/wau.png',
        'question':      'Apakah ini?',
        'options': [
          {'label': 'Wau Bulan',   'image': 'assets/images/wau.png',        'correct': true},
          {'label': 'Menara KL',   'image': 'assets/images/kltower.png',    'correct': false},
          {'label': 'Bunga Raya',  'image': 'assets/images/hibiscus.png',   'correct': false},
          {'label': 'Satay',       'image': 'assets/images/satay.png',      'correct': false},
        ],
      },
      3: {
        'name':          'Satay',
        'questionImage': 'assets/images/satay.png',
        'question':      'Apakah makanan ini?',
        'options': [
          {'label': 'Satay',       'image': 'assets/images/satay.png',      'correct': true},
          {'label': 'Nasi Lemak',  'image': 'assets/images/nasilemak.png',  'correct': false},
          {'label': 'Roti Canai',  'image': 'assets/images/roticanai.png',  'correct': false},
          {'label': 'Milo Ais',    'image': 'assets/images/miloais.png',    'correct': false},
        ],
      },
      4: {
        'name':          'Jalur Gemilang',
        'questionImage': 'assets/images/flag.png',
        'question':      'Bendera apakah ini?',
        'options': [
          {'label': 'Jalur Gemilang','image': 'assets/images/flag.png',     'correct': true},
          {'label': 'Menara KL',    'image': 'assets/images/kltower.png',   'correct': false},
          {'label': 'Wau Bulan',    'image': 'assets/images/wau.png',       'correct': false},
          {'label': 'Bunga Raya',   'image': 'assets/images/hibiscus.png',  'correct': false},
        ],
      },
      5: {
        'name':          'Bunga Raya',
        'questionImage': 'assets/images/hibiscus.png',
        'question':      'Bunga apakah ini?',
        'options': [
          {'label': 'Bunga Raya',  'image': 'assets/images/hibiscus.png',   'correct': true},
          {'label': 'Satay',       'image': 'assets/images/satay.png',      'correct': false},
          {'label': 'Wau Bulan',   'image': 'assets/images/wau.png',        'correct': false},
          {'label': 'Nasi Lemak',  'image': 'assets/images/nasilemak.png',  'correct': false},
        ],
      },
    },

    'zh': {
      1: {
        'name':          '椰浆饭',
        'questionImage': 'assets/images/nasilemak.png',
        'question':      '这是什么食物？',
        'options': [
          {'label': '椰浆饭',   'image': 'assets/images/nasilemak.png',  'correct': true},
          {'label': '印度煎饼', 'image': 'assets/images/roticanai.png',  'correct': false},
          {'label': '沙爹',     'image': 'assets/images/satay.png',      'correct': false},
          {'label': '美禄冰',   'image': 'assets/images/miloais.png',    'correct': false},
        ],
      },
      2: {
        'name':          '月亮风筝',
        'questionImage': 'assets/images/wau.png',
        'question':      '这叫什么？',
        'options': [
          {'label': '月亮风筝', 'image': 'assets/images/wau.png',        'correct': true},
          {'label': '吉隆坡塔', 'image': 'assets/images/kltower.png',    'correct': false},
          {'label': '大红花',   'image': 'assets/images/hibiscus.png',   'correct': false},
          {'label': '沙爹',     'image': 'assets/images/satay.png',      'correct': false},
        ],
      },
      3: {
        'name':          '沙爹',
        'questionImage': 'assets/images/satay.png',
        'question':      '这是什么食物？',
        'options': [
          {'label': '沙爹',     'image': 'assets/images/satay.png',      'correct': true},
          {'label': '椰浆饭',   'image': 'assets/images/nasilemak.png',  'correct': false},
          {'label': '印度煎饼', 'image': 'assets/images/roticanai.png',  'correct': false},
          {'label': '美禄冰',   'image': 'assets/images/miloais.png',    'correct': false},
        ],
      },
      4: {
        'name':          '马来西亚国旗',
        'questionImage': 'assets/images/flag.png',
        'question':      '这是哪个国家的国旗？',
        'options': [
          {'label': '马来西亚国旗','image': 'assets/images/flag.png',    'correct': true},
          {'label': '吉隆坡塔',   'image': 'assets/images/kltower.png', 'correct': false},
          {'label': '月亮风筝',   'image': 'assets/images/wau.png',     'correct': false},
          {'label': '大红花',     'image': 'assets/images/hibiscus.png','correct': false},
        ],
      },
      5: {
        'name':          '大红花',
        'questionImage': 'assets/images/hibiscus.png',
        'question':      '这是什么花？',
        'options': [
          {'label': '大红花',   'image': 'assets/images/hibiscus.png',   'correct': true},
          {'label': '沙爹',     'image': 'assets/images/satay.png',      'correct': false},
          {'label': '月亮风筝', 'image': 'assets/images/wau.png',        'correct': false},
          {'label': '椰浆饭',   'image': 'assets/images/nasilemak.png',  'correct': false},
        ],
      },
    },
  };
}