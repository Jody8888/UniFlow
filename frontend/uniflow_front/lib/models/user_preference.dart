import 'api_source_config.dart';
import '../utils/constants.dart';

class UserPreference {
  UserPreference({
    Set<String>? readNoticeIds,
    Set<String>? favoriteNoticeIds,
    Set<String>? dislikedGenres,
    Map<String, double>? customWeights,
    int? updateFrequencyMinutes,
    int? autoRefreshValue,
    String? autoRefreshUnit,
    List<ApiSourceConfig>? apiSources,
    String? activeApiSourceId,
    String? languageCode,
    String? homeSortMode,
    Map<String, bool>? sortAscendingByMode,
    String? themeMode,
    String? themePreset,
    String? customThemeColorHex,
    String? customForegroundColorHex,
    String? customBackgroundColorHex,
    String? timelineRange,
    String? settingsLayout,
    String? widgetListSize,
    String? widgetTimelineSize,
  })  : readNoticeIds = readNoticeIds ?? <String>{},
        favoriteNoticeIds = favoriteNoticeIds ?? <String>{},
        dislikedGenres = dislikedGenres ?? <String>{},
        customWeights = _normalizeWeights(customWeights),
        updateFrequencyMinutes = updateFrequencyMinutes ?? 24 * 60,
        autoRefreshValue = _normalizeAutoRefreshValue(autoRefreshValue),
        autoRefreshUnit = _normalizeAutoRefreshUnit(autoRefreshUnit),
        apiSources = _normalizeSources(apiSources),
        activeApiSourceId = activeApiSourceId ?? ApiSourceConfig.mock().id,
        languageCode = languageCode ?? AppLanguageOptions.system,
        homeSortMode = homeSortMode ?? AppSortModes.personalized,
        sortAscendingByMode = _normalizeSortAscending(sortAscendingByMode),
        themeMode = _normalizeThemeMode(themeMode),
        themePreset = _normalizeThemePreset(themePreset),
        customThemeColorHex = _normalizeCustomThemeColorHex(customThemeColorHex),
        customForegroundColorHex =
            _normalizeCustomThemeColorHex(customForegroundColorHex),
        customBackgroundColorHex =
            _normalizeCustomThemeColorHex(customBackgroundColorHex),
        timelineRange = _normalizeTimelineRange(timelineRange),
        settingsLayout = _normalizeSettingsLayout(settingsLayout),
        widgetListSize = _normalizeWidgetSize(widgetListSize),
        widgetTimelineSize = _normalizeWidgetSize(widgetTimelineSize);

  final Set<String> readNoticeIds;
  final Set<String> favoriteNoticeIds;
  final Set<String> dislikedGenres;
  final Map<String, double> customWeights;
  final int updateFrequencyMinutes;
  final int autoRefreshValue;
  final String autoRefreshUnit;
  final List<ApiSourceConfig> apiSources;
  final String activeApiSourceId;
  final String languageCode;
  final String homeSortMode;
  final Map<String, bool> sortAscendingByMode;
  final String themeMode;
  final String themePreset;
  final String? customThemeColorHex;
  final String? customForegroundColorHex;
  final String? customBackgroundColorHex;
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
      updateFrequencyMinutes: 24 * 60,
      autoRefreshValue: 1,
      autoRefreshUnit: AppRefreshUnits.day,
      apiSources: const <ApiSourceConfig>[ApiSourceConfig(
        id: 'fastapi-default',
        name: '本地 FastAPI',
        baseUrl: 'http://127.0.0.1:8888',
        noticePath: '/api/events',
        useMockData: false,
      )],
      activeApiSourceId: 'fastapi-default',
      languageCode: AppLanguageOptions.system,
      homeSortMode: AppSortModes.personalized,
      sortAscendingByMode: const <String, bool>{
        AppSortModes.personalized: false,
        AppSortModes.latest: false,
        AppSortModes.importance: false,
        AppSortModes.deadline: true,
      },
      themeMode: AppThemeModes.system,
      themePreset: AppThemePresets.xjtuRed,
      customThemeColorHex: null,
      customForegroundColorHex: null,
      customBackgroundColorHex: null,
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
      updateFrequencyMinutes:
          _readInt(json['updateFrequencyMinutes']) ?? 24 * 60,
      autoRefreshValue: _readInt(json['autoRefreshValue']) ??
          _legacyRefreshValue(_readInt(json['updateFrequencyMinutes'])),
      autoRefreshUnit: json['autoRefreshUnit']?.toString() ??
          _legacyRefreshUnit(_readInt(json['updateFrequencyMinutes'])),
      apiSources: _readSources(json['apiSources']),
      activeApiSourceId: json['activeApiSourceId']?.toString(),
      languageCode: json['languageCode']?.toString(),
      homeSortMode: json['homeSortMode']?.toString(),
      sortAscendingByMode: _readBoolMap(json['sortAscendingByMode']),
      themeMode: json['themeMode']?.toString(),
      themePreset: json['themePreset']?.toString(),
      customThemeColorHex: json['customThemeColorHex']?.toString(),
      customForegroundColorHex: json['customForegroundColorHex']?.toString(),
      customBackgroundColorHex: json['customBackgroundColorHex']?.toString(),
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
      'updateFrequencyMinutes': resolvedAutoRefreshMinutes,
      'autoRefreshValue': autoRefreshValue,
      'autoRefreshUnit': autoRefreshUnit,
      'apiSources': apiSources.map((item) => item.toJson()).toList(),
      'activeApiSourceId': activeApiSourceId,
      'languageCode': languageCode,
      'homeSortMode': homeSortMode,
      'sortAscendingByMode': sortAscendingByMode,
      'themeMode': themeMode,
      'themePreset': themePreset,
      'customThemeColorHex': customThemeColorHex,
      'customForegroundColorHex': customForegroundColorHex,
      'customBackgroundColorHex': customBackgroundColorHex,
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
    int? autoRefreshValue,
    String? autoRefreshUnit,
    List<ApiSourceConfig>? apiSources,
    String? activeApiSourceId,
    String? languageCode,
    String? homeSortMode,
    Map<String, bool>? sortAscendingByMode,
    String? themeMode,
    String? themePreset,
    String? customThemeColorHex,
    String? customForegroundColorHex,
    String? customBackgroundColorHex,
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
      autoRefreshValue: autoRefreshValue ?? this.autoRefreshValue,
      autoRefreshUnit: autoRefreshUnit ?? this.autoRefreshUnit,
      apiSources: apiSources ?? this.apiSources,
      activeApiSourceId: activeApiSourceId ?? this.activeApiSourceId,
      languageCode: languageCode ?? this.languageCode,
      homeSortMode: homeSortMode ?? this.homeSortMode,
      sortAscendingByMode: sortAscendingByMode ?? this.sortAscendingByMode,
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
      customThemeColorHex: customThemeColorHex ?? this.customThemeColorHex,
      customForegroundColorHex:
          customForegroundColorHex ?? this.customForegroundColorHex,
      customBackgroundColorHex:
          customBackgroundColorHex ?? this.customBackgroundColorHex,
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

  bool sortAscendingOf(String mode) {
    return sortAscendingByMode[mode] ?? false;
  }

  int get resolvedAutoRefreshMinutes {
    return AppRefreshUnits.toMinutes(
      value: autoRefreshValue,
      unit: autoRefreshUnit,
    );
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
        id: 'fastapi-default',
        name: '本地 FastAPI',
        baseUrl: 'http://127.0.0.1:8888',
        noticePath: '/api/events',
        useMockData: false,
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

  static Map<String, bool> _readBoolMap(dynamic value) {
    if (value is! Map) {
      return <String, bool>{};
    }
    final result = <String, bool>{};
    for (final mode in AppSortModes.values) {
      final raw = value[mode];
      if (raw is bool) {
        result[mode] = raw;
      } else if (raw is String) {
        result[mode] = raw.toLowerCase() == 'true';
      }
    }
    return result;
  }

  static List<ApiSourceConfig> _readSources(dynamic value) {
    if (value is! List) {
      return const <ApiSourceConfig>[ApiSourceConfig(
        id: 'fastapi-default',
        name: '本地 FastAPI',
        baseUrl: 'http://127.0.0.1:8888',
        noticePath: '/api/events',
        useMockData: false,
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
            id: 'fastapi-default',
            name: '本地 FastAPI',
            baseUrl: 'http://127.0.0.1:8888',
            noticePath: '/api/events',
            useMockData: false,
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

  static int _normalizeAutoRefreshValue(int? value) {
    if (value == null) {
      return 1;
    }
    if (value < 0) {
      return 0;
    }
    return value;
  }

  static String _normalizeAutoRefreshUnit(String? value) {
    if (AppRefreshUnits.values.contains(value)) {
      return value!;
    }
    return AppRefreshUnits.day;
  }

  static int _legacyRefreshValue(int? minutes) {
    final safeMinutes = minutes ?? 24 * 60;
    if (safeMinutes <= 0) {
      return 0;
    }
    if (safeMinutes % (60 * 24 * 7) == 0) {
      return safeMinutes ~/ (60 * 24 * 7);
    }
    if (safeMinutes % (60 * 24) == 0) {
      return safeMinutes ~/ (60 * 24);
    }
    if (safeMinutes % 60 == 0) {
      return safeMinutes ~/ 60;
    }
    return safeMinutes;
  }

  static String _legacyRefreshUnit(int? minutes) {
    final safeMinutes = minutes ?? 24 * 60;
    if (safeMinutes <= 0) {
      return AppRefreshUnits.day;
    }
    if (safeMinutes % (60 * 24 * 7) == 0) {
      return AppRefreshUnits.week;
    }
    if (safeMinutes % (60 * 24) == 0) {
      return AppRefreshUnits.day;
    }
    if (safeMinutes % 60 == 0) {
      return AppRefreshUnits.hour;
    }
    return AppRefreshUnits.minute;
  }

  static Map<String, bool> _normalizeSortAscending(Map<String, bool>? value) {
    return <String, bool>{
      AppSortModes.personalized:
          value?[AppSortModes.personalized] ?? false,
      AppSortModes.latest: value?[AppSortModes.latest] ?? false,
      AppSortModes.importance: value?[AppSortModes.importance] ?? false,
      AppSortModes.deadline: value?[AppSortModes.deadline] ?? true,
    };
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
