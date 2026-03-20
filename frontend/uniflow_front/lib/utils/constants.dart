import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'UniFlow 校园通知';
  static const String apiBaseUrl = 'https://example.com';
  static const String noticePath = '/api/notices';
  static const bool useMockData = true;
  static const int pageSize = 6;

  static const List<String> noticeGenres = <String>[
    '考试',
    '活动',
    '竞赛',
    '国际',
    '后勤',
    '教务',
    '其他',
  ];

  static const List<String> gradeYears = <String>[
    '大一',
    '大二',
    '大三',
    '大四',
  ];

  static const List<String> noticeSources = <String>[
    '教务处',
    '党委',
    '团委',
    '彭康书院',
    '文治书院',
    '宗濂书院',
    '启德书院',
    '仲英书院',
    '励志书院',
    '崇实书院',
    '南洋书院',
    '数学学院',
    '物理学院',
    '化学学院',
    '前沿院',
    '机械学院',
    '电气学院',
    '能动学院',
    '电信学部',
    '人工智能学院',
    '材料学院',
    '人居学院',
    '生命学院',
    '航天学院',
    '化工学院',
    '仪器科学与技术学院',
    '医学部',
    '经金学院',
    '金禾经济中心',
    '管理学院',
    '公管学院',
    '人文学院',
    '新媒体学院',
    '马克思主义学院',
    '法学院',
    '外国语学院',
    '体育学院',
    '继续（网络）教育学院',
    '国际教育学院',
    '钱学森学院',
    '创新创业学院',
    '未来技术学院',
    '西交米兰学院',
    '其他',
  ];

  static const List<String> collegeOptions = <String>[
    '数学学院',
    '物理学院',
    '化学学院',
    '前沿院',
    '机械学院',
    '电气学院',
    '能动学院',
    '电信学部',
    '人工智能学院',
    '材料学院',
    '人居学院',
    '生命学院',
    '航天学院',
    '化工学院',
    '仪器科学与技术学院',
    '医学部',
    '经金学院',
    '金禾经济中心',
    '管理学院',
    '公管学院',
    '人文学院',
    '新媒体学院',
    '马克思主义学院',
    '法学院',
    '外国语学院',
    '体育学院',
    '继续（网络）教育学院',
    '国际教育学院',
    '钱学森学院',
    '创新创业学院',
    '未来技术学院',
    '西交米兰学院',
    '其他',
  ];

  static const List<String> academyOptions = <String>[
    '彭康书院',
    '文治书院',
    '宗濂书院',
    '启德书院',
    '仲英书院',
    '励志书院',
    '崇实书院',
    '南洋书院',
    '其他',
  ];

  static const Set<String> schoolLevelSources = <String>{
    '教务处',
    '党委',
    '团委',
  };

  static const Map<String, Map<String, double>> defaultGenreWeights =
      <String, Map<String, double>>{
    '大一': <String, double>{
      '活动': 0.15,
      '后勤': 0.10,
      '教务': 0.10,
      '其他': 0.05,
    },
    '大二': <String, double>{
      '考试': 0.10,
      '活动': 0.10,
      '竞赛': 0.15,
      '教务': 0.10,
    },
    '大三': <String, double>{
      '竞赛': 0.20,
      '国际': 0.10,
      '教务': 0.10,
    },
    '大四': <String, double>{
      '考试': 0.15,
      '教务': 0.20,
      '国际': 0.10,
    },
  };
}

class AppRoutes {
  static const String home = '/';
  static const String noticeDetail = '/notice-detail';
  static const String userInfo = '/user-info';
  static const String setting = '/setting';
}

class AppStorageKeys {
  static const String noticeCache = 'notice_cache';
  static const String studentInfo = 'student_info';
  static const String preference = 'user_preference';
}

class AppSpacing {
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
}

class AppRadii {
  static const double small = 12;
  static const double medium = 16;
  static const double large = 20;
}

class AppColors {
  static const Color brandPrimary = Color(0xFF8D1F24);
  static const Color surface = Color(0xFFFFFBF7);
  static const Color textPrimary = Color(0xFF2D1F1A);
  static const Color textSecondary = Color(0xFF7A6A63);
  static const Color danger = Color(0xFFB42318);
  static const Color warningBackground = Color(0xFFFFF3D6);
  static const Color infoBackground = Color(0xFFF3E8DE);
  static const Color genreChip = Color(0xFFFFE8C2);
  static const Color sourceChip = Color(0xFFE7D6C8);
  static const Color importanceChip = Color(0xFFFFD6CC);
  static const Color expiredChip = Color(0xFFE4E0DE);
  static const Color activeChip = Color(0xFFD7F1E1);
  static const Color readChip = Color(0xFFE9ECEF);
  static const Color readCard = Color(0xFFF7F4F2);
  static const Color timelinePast = Color(0xFFF3F1F0);
  static const Color timelineFuture = Color(0xFFFFF5EA);
}

class AppTheme {
  static ThemeData buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
          side: const BorderSide(color: Color(0xFFF0E2D7)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          borderSide: const BorderSide(color: Color(0xFFE7DACE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          borderSide: const BorderSide(color: AppColors.brandPrimary),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
        ),
      ),
    );
  }
}
