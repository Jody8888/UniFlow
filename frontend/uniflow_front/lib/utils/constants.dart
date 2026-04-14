import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'UniFlow 校园通知';
  static const String apiBaseUrl = 'http://127.0.0.1:8888';
  static const String noticePath = '/api/events';
  static const bool useMockData = false;
  static const int pageSize = 30;
  static const String apiDefaultSortBy = 'trending';

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

  static const List<int> updateFrequencyOptions = <int>[-1, 5, 15, 30, 60];

  static const Map<String, String> sourceAliases = <String, String>{
    'dean.xjtu.edu.cn': '教务处',
    'dw.xjtu.edu.cn': '党委',
    'youth.xjtu.edu.cn': '团委',
    'international.xjtu.edu.cn': '国际教育学院',
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

class AppSortModes {
  static const String personalized = 'personalized';
  static const String latest = 'latest';
  static const String importance = 'importance';
  static const String deadline = 'deadline';

  static const List<String> values = <String>[
    personalized,
    latest,
    importance,
    deadline,
  ];

  static String apiSortByOf(String value) {
    switch (value) {
      case latest:
        return 'timeline_date';
      case importance:
        return 'importance_time';
      case deadline:
        return 'timeline_date';
      case personalized:
      default:
        return AppConstants.apiDefaultSortBy;
    }
  }

  static String labelOf(String value) {
    switch (value) {
      case latest:
        return '最新发布';
      case importance:
        return '重要度';
      case deadline:
        return '截止时间';
      case personalized:
      default:
        return '个性化排序';
    }
  }
}

class AppSortDirections {
  static const String ascending = 'ascending';
  static const String descending = 'descending';

  static const List<String> values = <String>[ascending, descending];
}

class AppLanguageOptions {
  static const String system = 'system';
  static const String zhCn = 'zh_CN';
  static const String enUs = 'en_US';

  static const List<String> values = <String>[system, zhCn, enUs];

  static String labelOf(String value) {
    switch (value) {
      case zhCn:
        return '简体中文';
      case enUs:
        return 'English';
      case system:
      default:
        return '跟随系统';
    }
  }
}

class AppThemeModes {
  static const String system = 'system';
  static const String light = 'light';
  static const String dark = 'dark';

  static const List<String> values = <String>[system, light, dark];
}

class AppTimelineRanges {
  static const String week = '7d';
  static const String month = '30d';
  static const String quarter = '90d';

  static const List<String> values = <String>[week, month, quarter];

  static int daysFor(String value) {
    switch (value) {
      case month:
        return 30;
      case quarter:
        return 90;
      case week:
      default:
        return 7;
    }
  }
}

class AppSettingsLayouts {
  static const String horizontalTabs = 'horizontal_tabs';
  static const String verticalTabs = 'vertical_tabs';
  static const String secondaryMenu = 'secondary_menu';

  static const List<String> values = <String>[
    horizontalTabs,
    verticalTabs,
    secondaryMenu,
  ];
}

class AppWidgetSizes {
  static const String small = 'small';
  static const String medium = 'medium';
  static const String large = 'large';

  static const List<String> values = <String>[small, medium, large];
}

class AppThemePresets {
  static const String xjtuRed = 'xjtu_red';
  static const String oceanBlue = 'ocean_blue';
  static const String forestGreen = 'forest_green';
  static const String amberGold = 'amber_gold';

  static const List<String> values = <String>[
    xjtuRed,
    oceanBlue,
    forestGreen,
    amberGold,
  ];

  static const Map<String, AppThemePalette> palettes =
      <String, AppThemePalette>{
    xjtuRed: AppThemePalette(
      seedColor: Color(0xFF8D1F24),
      foregroundColor: Color(0xFF2D1F1A),
      backgroundColor: Color(0xFFFFFBF7),
    ),
    oceanBlue: AppThemePalette(
      seedColor: Color(0xFF0E7490),
      foregroundColor: Color(0xFF122935),
      backgroundColor: Color(0xFFF3FAFC),
    ),
    forestGreen: AppThemePalette(
      seedColor: Color(0xFF2F6B3B),
      foregroundColor: Color(0xFF1E2A20),
      backgroundColor: Color(0xFFF5FBF6),
    ),
    amberGold: AppThemePalette(
      seedColor: Color(0xFFB7791F),
      foregroundColor: Color(0xFF332515),
      backgroundColor: Color(0xFFFFFAF1),
    ),
  };

  static const List<Color> colorChoices = <Color>[
    Color(0xFF8D1F24),
    Color(0xFF0E7490),
    Color(0xFF2F6B3B),
    Color(0xFFB7791F),
    Color(0xFF7C3AED),
    Color(0xFFD946EF),
    Color(0xFF2563EB),
    Color(0xFFDC2626),
    Color(0xFFEA580C),
    Color(0xFF16A34A),
    Color(0xFFF8FAFC),
    Color(0xFF111827),
    Color(0xFFFDE68A),
    Color(0xFFE0F2FE),
    Color(0xFFF5F3FF),
    Color(0xFFFCE7F3),
  ];

  static Color seedColorOf(String preset) {
    return palettes[preset]?.seedColor ?? AppColors.brandPrimary;
  }

  static Color foregroundColorOf(String preset) {
    return palettes[preset]?.foregroundColor ?? AppColors.textPrimary;
  }

  static Color backgroundColorOf(String preset) {
    return palettes[preset]?.backgroundColor ?? AppColors.surface;
  }

  static Color? parseHexColor(String? value) {
    final normalized = value?.trim() ?? '';
    if (!RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(normalized)) {
      return null;
    }
    final hex =
        normalized.startsWith('#') ? normalized.substring(1) : normalized;
    return Color(int.parse('FF$hex', radix: 16));
  }

  static String toHex(Color color) {
    final hex = color.toARGB32().toRadixString(16).substring(2).toUpperCase();
    return '#$hex';
  }
}

class AppThemePalette {
  const AppThemePalette({
    required this.seedColor,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final Color seedColor;
  final Color foregroundColor;
  final Color backgroundColor;
}

class DeveloperInfo {
  static const String teamName = 'UniFlow';
  static const String version = '1.0.0';
  static const String maintainer = 'Jung233 & Jody & Thusci';
  static const String description = """
本项目由Jung233,Jody,Thusci社员共同开发，旨在将校内分散的通知信息进行统一抓取、结构化处理与时间线化展示，提升信息获取效率。

技术架构：
基于 Python + FastAPI + PostgreSQL + Flutter 构建，形成完整的前后端一体化解决方案。

核心功能：
多源通知聚合：支持抓取校内多个信息来源，包括教务处、微信公众号、智慧学生社区等
时间线化展示：对通知进行统一排序与结构化呈现
智能信息处理：引入人工智能技术，实现通知内容的自动抓取、筛选与精炼

项目分工：
  前端开发： Thusci
  后端开发：
    爬虫与 API 逆向：Jung233、Jody8888
    AI 处理与数据库设计：Jody8888、Thusci
    FastAPI 服务搭建：Jody8888

特别鸣谢：
  XJTU ANA 社团
  Silicon Flow
  Google Antigravity
  OpenAI Codex
  Webmin Panel
  """;
  static const String contact = 'https://github.com/Jody8888/Uniflow';
  static const String buyMeACoffeeUrl = 'https://buymeacoffee.com/thusci';
  static const String afdianUrl = 'https://ifdian.net/a/thusci';
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
  static ThemeData buildTheme({
    required Brightness brightness,
    required Color seedColor,
    Color? foregroundColor,
    Color? backgroundColor,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;
    final requestedBackground = backgroundColor ?? AppColors.surface;
    final requestedForeground = foregroundColor ?? AppColors.textPrimary;
    final resolvedBackground = isDark
        ? Color.alphaBlend(
            requestedBackground.withValues(alpha: 0.12),
            colorScheme.surface,
          )
        : requestedBackground;
    final resolvedForeground = isDark
        ? Color.alphaBlend(
            requestedForeground.withValues(alpha: 0.18),
            colorScheme.onSurface,
          )
        : requestedForeground;
    final cardColor = isDark
        ? Color.alphaBlend(
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.56),
            resolvedBackground,
          )
        : Colors.white;
    final softBackground = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.06),
      resolvedBackground,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: resolvedBackground,
      canvasColor: resolvedBackground,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: resolvedForeground,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
          side: BorderSide(
            color:
                isDark ? colorScheme.outlineVariant : const Color(0xFFF0E2D7),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: cardColor),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Color.alphaBlend(
                colorScheme.surfaceContainerHigh.withValues(alpha: 0.72),
                resolvedBackground,
              )
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          borderSide: BorderSide(
            color:
                isDark ? colorScheme.outlineVariant : const Color(0xFFE7DACE),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        backgroundColor: softBackground,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(color: resolvedForeground),
      ),
      listTileTheme: ListTileThemeData(
        textColor: resolvedForeground,
        iconColor: resolvedForeground.withValues(alpha: 0.86),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: 12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        labelColor: colorScheme.onPrimaryContainer,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
      ),
      textTheme: Typography.material2021().black.apply(
            bodyColor: resolvedForeground,
            displayColor: resolvedForeground,
          ),
    );
  }
}
