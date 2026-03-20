import 'api_source_config.dart';
import '../utils/constants.dart';

class UserPreference {
  UserPreference({
    Set<String>? readNoticeIds,
    Set<String>? favoriteNoticeIds,
    Set<String>? dislikedGenres,
    Map<String, double>? customWeights,
    int? updateFrequencyMinutes,
    List<ApiSourceConfig>? apiSources,
    String? activeApiSourceId,
    String? languageCode,
    String? homeSortMode,
    String? themeMode,
    String? themePreset,
    String? customThemeColorHex,
    String? timelineRange,
    String? settingsLayout,
    String? widgetListSize,
    String? widgetTimelineSize,
  })  : readNoticeIds = readNoticeIds ?? <String>{},
        favoriteNoticeIds = favoriteNoticeIds ?? <String>{},
        dislikedGenres = dislikedGenres ?? <String>{},
        customWeights = _normalizeWeights(customWeights),
        updateFrequencyMinutes = updateFrequencyMinutes ?? -1,
        apiSources = _normalizeSources(apiSources),
        activeApiSourceId = activeApiSourceId ?? ApiSourceConfig.mock().id,
        languageCode = languageCode ?? AppLanguageOptions.system,
        homeSortMode = homeSortMode ?? AppSortModes.personalized,
        themeMode = _normalizeThemeMode(themeMode),
        themePreset = _normalizeThemePreset(themePreset),
        customThemeColorHex = _normalizeCustomThemeColorHex(customThemeColorHex),
        timelineRange = _normalizeTimelineRange(timelineRange),
        settingsLayout = _normalizeSettingsLayout(settingsLayout),
        widgetListSize = _normalizeWidgetSize(widgetListSize),
        widgetTimelineSize = _normalizeWidgetSize(widgetTimelineSize);

  final Set<String> readNoticeIds;
  final Set<String> favoriteNoticeIds;
  final Set<String> dislikedGenres;
  final Map<String, double> customWeights;
  final int updateFrequencyMinutes;
  final List<ApiSourceConfig> apiSources;
  final String activeApiSourceId;
  final String languageCode;
  final String homeSortMode;
  final String themeMode;
  final String themePreset;
  final String? customThemeColorHex;
  final String timelineRange;
  final String settingsLayout;
  final String widgetListSize;
  final String widgetTimelineSize;

  factory UserPreference.empty() {
    return UserPreference(
      readNoticeIds: <String>{},
      favoriteNoticeIds: <String>{},
      dislikedGenres: <String>{},
      customWeights: <String, double>{
        for (final genre in AppConstants.noticeGenres) genre: 0,
      },
      updateFrequencyMinutes: -1,
      apiSources: const <ApiSourceConfig>[ApiSourceConfig(
        id: 'mock-default',
        name: '内置 Mock 数据',
        baseUrl: 'https://example.com',
        noticePath: '/api/notices',
        useMockData: true,
      )],
      activeApiSourceId: 'mock-default',
      languageCode: AppLanguageOptions.system,
      homeSortMode: AppSortModes.personalized,
      themeMode: AppThemeModes.system,
      themePreset: AppThemePresets.xjtuRed,
      customThemeColorHex: null,
      timelineRange: AppTimelineRanges.month,
      settingsLayout: AppSettingsLayouts.horizontalTabs,
      widgetListSize: AppWidgetSizes.medium,
      widgetTimelineSize: AppWidgetSizes.large,
    );
  }

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      readNoticeIds: _readStringSet(json['readNoticeIds']),
      favoriteNoticeIds: _readStringSet(json['favoriteNoticeIds']),
      dislikedGenres: _readStringSet(json['dislikedGenres']),
      customWeights: _readDoubleMap(json['customWeights']),
      updateFrequencyMinutes: _readInt(json['updateFrequencyMinutes']) ?? -1,
      apiSources: _readSources(json['apiSources']),
      activeApiSourceId: json['activeApiSourceId']?.toString(),
      languageCode: json['languageCode']?.toString(),
      homeSortMode: json['homeSortMode']?.toString(),
      themeMode: json['themeMode']?.toString(),
      themePreset: json['themePreset']?.toString(),
      customThemeColorHex: json['customThemeColorHex']?.toString(),
      timelineRange: json['timelineRange']?.toString(),
      settingsLayout: json['settingsLayout']?.toString(),
      widgetListSize: json['widgetListSize']?.toString(),
      widgetTimelineSize: json['widgetTimelineSize']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'readNoticeIds': readNoticeIds.toList(),
      'favoriteNoticeIds': favoriteNoticeIds.toList(),
      'dislikedGenres': dislikedGenres.toList(),
      'customWeights': customWeights,
      'updateFrequencyMinutes': updateFrequencyMinutes,
      'apiSources': apiSources.map((item) => item.toJson()).toList(),
      'activeApiSourceId': activeApiSourceId,
      'languageCode': languageCode,
      'homeSortMode': homeSortMode,
      'themeMode': themeMode,
      'themePreset': themePreset,
      'customThemeColorHex': customThemeColorHex,
      'timelineRange': timelineRange,
      'settingsLayout': settingsLayout,
      'widgetListSize': widgetListSize,
      'widgetTimelineSize': widgetTimelineSize,
    };
  }

  UserPreference copyWith({
    Set<String>? readNoticeIds,
    Set<String>? favoriteNoticeIds,
    Set<String>? dislikedGenres,
    Map<String, double>? customWeights,
    int? updateFrequencyMinutes,
    List<ApiSourceConfig>? apiSources,
    String? activeApiSourceId,
    String? languageCode,
    String? homeSortMode,
    String? themeMode,
    String? themePreset,
    String? customThemeColorHex,
    String? timelineRange,
    String? settingsLayout,
    String? widgetListSize,
    String? widgetTimelineSize,
  }) {
    return UserPreference(
      readNoticeIds: readNoticeIds ?? this.readNoticeIds,
      favoriteNoticeIds: favoriteNoticeIds ?? this.favoriteNoticeIds,
      dislikedGenres: dislikedGenres ?? this.dislikedGenres,
      customWeights: customWeights ?? this.customWeights,
      updateFrequencyMinutes:
          updateFrequencyMinutes ?? this.updateFrequencyMinutes,
      apiSources: apiSources ?? this.apiSources,
      activeApiSourceId: activeApiSourceId ?? this.activeApiSourceId,
      languageCode: languageCode ?? this.languageCode,
      homeSortMode: homeSortMode ?? this.homeSortMode,
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
      customThemeColorHex: customThemeColorHex ?? this.customThemeColorHex,
      timelineRange: timelineRange ?? this.timelineRange,
      settingsLayout: settingsLayout ?? this.settingsLayout,
      widgetListSize: widgetListSize ?? this.widgetListSize,
      widgetTimelineSize: widgetTimelineSize ?? this.widgetTimelineSize,
    );
  }

  ApiSourceConfig get activeApiSource {
    return apiSources.where((item) => item.id == activeApiSourceId).firstOrNull ??
        apiSources.first;
  }

  static Map<String, double> _normalizeWeights(Map<String, double>? weights) {
    final normalized = <String, double>{
      for (final genre in AppConstants.noticeGenres) genre: 0,
    };
    if (weights == null) {
      return normalized;
    }
    for (final entry in weights.entries) {
      if (AppConstants.noticeGenres.contains(entry.key)) {
        normalized[entry.key] = _clampWeight(entry.value);
      }
    }
    return normalized;
  }

  static List<ApiSourceConfig> _normalizeSources(List<ApiSourceConfig>? sources) {
    if (sources == null || sources.isEmpty) {
      return const <ApiSourceConfig>[ApiSourceConfig(
        id: 'mock-default',
        name: '内置 Mock 数据',
        baseUrl: 'https://example.com',
        noticePath: '/api/notices',
        useMockData: true,
      )];
    }
    return sources;
  }

  static Set<String> _readStringSet(dynamic value) {
    if (value is! List) {
      return <String>{};
    }
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  static Map<String, double> _readDoubleMap(dynamic value) {
    if (value is! Map) {
      return <String, double>{};
    }
    final result = <String, double>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      if (!AppConstants.noticeGenres.contains(key)) {
        continue;
      }
      final raw = entry.value;
      if (raw is num) {
        result[key] = _clampWeight(raw.toDouble());
        continue;
      }
      final parsed = double.tryParse(raw?.toString() ?? '');
      if (parsed != null) {
        result[key] = _clampWeight(parsed);
      }
    }
    return result;
  }

  static List<ApiSourceConfig> _readSources(dynamic value) {
    if (value is! List) {
      return const <ApiSourceConfig>[ApiSourceConfig(
        id: 'mock-default',
        name: '内置 Mock 数据',
        baseUrl: 'https://example.com',
        noticePath: '/api/notices',
        useMockData: true,
      )];
    }
    final items = value
        .whereType<Map>()
        .map((item) => ApiSourceConfig.fromJson(
              item.map((key, val) => MapEntry(key.toString(), val)),
            ))
        .toList();
    return items.isEmpty
        ? const <ApiSourceConfig>[ApiSourceConfig(
            id: 'mock-default',
            name: '内置 Mock 数据',
            baseUrl: 'https://example.com',
            noticePath: '/api/notices',
            useMockData: true,
          )]
        : items;
  }

  static int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static double _clampWeight(double value) {
    if (value < -0.5) {
      return -0.5;
    }
    if (value > 0.5) {
      return 0.5;
    }
    return value;
  }

  static String _normalizeThemeMode(String? value) {
    if (AppThemeModes.values.contains(value)) {
      return value!;
    }
    return AppThemeModes.system;
  }

  static String _normalizeThemePreset(String? value) {
    if (AppThemePresets.values.contains(value)) {
      return value!;
    }
    return AppThemePresets.xjtuRed;
  }

  static String? _normalizeCustomThemeColorHex(String? value) {
    final color = AppThemePresets.parseHexColor(value);
    if (color == null) {
      return null;
    }
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  static String _normalizeTimelineRange(String? value) {
    if (AppTimelineRanges.values.contains(value)) {
      return value!;
    }
    return AppTimelineRanges.month;
  }

  static String _normalizeSettingsLayout(String? value) {
    if (AppSettingsLayouts.values.contains(value)) {
      return value!;
    }
    return AppSettingsLayouts.horizontalTabs;
  }

  static String _normalizeWidgetSize(String? value) {
    if (AppWidgetSizes.values.contains(value)) {
      return value!;
    }
    return AppWidgetSizes.medium;
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
