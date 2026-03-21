import 'package:flutter/foundation.dart';

import '../models/api_source_config.dart';
import '../models/student_info.dart';
import '../models/user_preference.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({
    required StorageService storageService,
  }) : _storageService = storageService;

  final StorageService _storageService;

  StudentInfo? _studentInfo;
  UserPreference _preference = UserPreference.empty();
  bool _initialized = false;

  StudentInfo? get studentInfo => _studentInfo;
  UserPreference get preference => _preference;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    final results = await Future.wait<dynamic>([
      _storageService.loadStudentInfo(),
      _storageService.loadPreference(),
    ]);
    _studentInfo = results[0] as StudentInfo?;
    _preference = results[1] as UserPreference;
    _initialized = true;
    notifyListeners();
  }

  Future<void> saveStudentInfo(StudentInfo info) async {
    _studentInfo = info;
    await _storageService.saveStudentInfo(info);
    notifyListeners();
  }

  Future<void> markNoticeRead(String noticeId) async {
    final nextReadIds = Set<String>.from(_preference.readNoticeIds)
      ..add(noticeId);
    await _savePreference(_preference.copyWith(readNoticeIds: nextReadIds));
  }

  Future<void> toggleFavoriteNotice(String noticeId) async {
    final nextFavoriteIds = Set<String>.from(_preference.favoriteNoticeIds);
    if (nextFavoriteIds.contains(noticeId)) {
      nextFavoriteIds.remove(noticeId);
    } else {
      nextFavoriteIds.add(noticeId);
    }
    await _savePreference(
      _preference.copyWith(favoriteNoticeIds: nextFavoriteIds),
    );
  }

  Future<void> setFavoriteStateForBatch(
    Iterable<String> noticeIds, {
    required bool favorite,
  }) async {
    final nextFavoriteIds = Set<String>.from(_preference.favoriteNoticeIds);
    if (favorite) {
      nextFavoriteIds.addAll(noticeIds);
    } else {
      nextFavoriteIds.removeAll(noticeIds);
    }
    await _savePreference(
      _preference.copyWith(favoriteNoticeIds: nextFavoriteIds),
    );
  }

  Future<void> addDislikedGenre(String genre) async {
    final genres = Set<String>.from(_preference.dislikedGenres)..add(genre);
    await _savePreference(_preference.copyWith(dislikedGenres: genres));
  }

  Future<void> removeDislikedGenre(String genre) async {
    final genres = Set<String>.from(_preference.dislikedGenres)..remove(genre);
    await _savePreference(_preference.copyWith(dislikedGenres: genres));
  }

  Future<void> updateCustomWeight(String genre, double weight) async {
    final weights = Map<String, double>.from(_preference.customWeights)
      ..[genre] = _clampWeight(weight);
    await _savePreference(_preference.copyWith(customWeights: weights));
  }

  Future<void> updateUpdateFrequency(int minutes) async {
    await _savePreference(
      _preference.copyWith(updateFrequencyMinutes: minutes),
    );
  }

  Future<void> updateLanguageCode(String value) async {
    final safe = AppLanguageOptions.values.contains(value)
        ? value
        : AppLanguageOptions.system;
    await _savePreference(_preference.copyWith(languageCode: safe));
  }

  Future<void> updateHomeSortMode(String value) async {
    final safe = AppSortModes.values.contains(value)
        ? value
        : AppSortModes.personalized;
    await _savePreference(_preference.copyWith(homeSortMode: safe));
  }

  Future<void> updateSortDirection(String mode, bool ascending) async {
    final safeMode = AppSortModes.values.contains(mode)
        ? mode
        : AppSortModes.personalized;
    final nextMap = Map<String, bool>.from(_preference.sortAscendingByMode)
      ..[safeMode] = ascending;
    await _savePreference(_preference.copyWith(sortAscendingByMode: nextMap));
  }

  Future<void> updateThemeMode(String value) async {
    final safe = AppThemeModes.values.contains(value)
        ? value
        : AppThemeModes.system;
    await _savePreference(_preference.copyWith(themeMode: safe));
  }

  Future<void> updateThemePreset(String value) async {
    final safe = AppThemePresets.values.contains(value)
        ? value
        : AppThemePresets.xjtuRed;
    await _savePreference(_preference.copyWith(themePreset: safe));
  }

  Future<void> updateCustomThemeColor(String? value) async {
    final nextPreference = UserPreference(
      readNoticeIds: _preference.readNoticeIds,
      dislikedGenres: _preference.dislikedGenres,
      customWeights: _preference.customWeights,
      updateFrequencyMinutes: _preference.updateFrequencyMinutes,
      apiSources: _preference.apiSources,
      activeApiSourceId: _preference.activeApiSourceId,
      languageCode: _preference.languageCode,
      homeSortMode: _preference.homeSortMode,
      sortAscendingByMode: _preference.sortAscendingByMode,
      themeMode: _preference.themeMode,
      themePreset: _preference.themePreset,
      customThemeColorHex: value,
      customForegroundColorHex: _preference.customForegroundColorHex,
      customBackgroundColorHex: _preference.customBackgroundColorHex,
      timelineRange: _preference.timelineRange,
      settingsLayout: _preference.settingsLayout,
      favoriteNoticeIds: _preference.favoriteNoticeIds,
      widgetListSize: _preference.widgetListSize,
      widgetTimelineSize: _preference.widgetTimelineSize,
    );
    await _savePreference(nextPreference);
  }

  Future<void> updateCustomForegroundColor(String? value) async {
    await _savePreference(
      _preference.copyWith(customForegroundColorHex: value),
    );
  }

  Future<void> updateCustomBackgroundColor(String? value) async {
    await _savePreference(
      _preference.copyWith(customBackgroundColorHex: value),
    );
  }

  Future<void> updateTimelineRange(String value) async {
    final safe = AppTimelineRanges.values.contains(value)
        ? value
        : AppTimelineRanges.month;
    await _savePreference(_preference.copyWith(timelineRange: safe));
  }

  Future<void> updateSettingsLayout(String value) async {
    final safe = AppSettingsLayouts.values.contains(value)
        ? value
        : AppSettingsLayouts.horizontalTabs;
    await _savePreference(_preference.copyWith(settingsLayout: safe));
  }

  Future<void> updateWidgetListSize(String value) async {
    final safe = AppWidgetSizes.values.contains(value)
        ? value
        : AppWidgetSizes.medium;
    await _savePreference(_preference.copyWith(widgetListSize: safe));
  }

  Future<void> updateWidgetTimelineSize(String value) async {
    final safe = AppWidgetSizes.values.contains(value)
        ? value
        : AppWidgetSizes.large;
    await _savePreference(_preference.copyWith(widgetTimelineSize: safe));
  }

  Future<void> addApiSource(ApiSourceConfig source) async {
    final sources = List<ApiSourceConfig>.from(_preference.apiSources)..add(source);
    await _savePreference(
      _preference.copyWith(
        apiSources: sources,
        activeApiSourceId: source.id,
      ),
    );
  }

  Future<void> updateApiSource(ApiSourceConfig source) async {
    final sources = _preference.apiSources
        .map((item) => item.id == source.id ? source : item)
        .toList();
    await _savePreference(_preference.copyWith(apiSources: sources));
  }

  Future<void> removeApiSource(String sourceId) async {
    final sources = _preference.apiSources
        .where((item) => item.id != sourceId)
        .toList();
    if (sources.isEmpty) {
      return;
    }
    final activeId = _preference.activeApiSourceId == sourceId
        ? sources.first.id
        : _preference.activeApiSourceId;
    await _savePreference(
      _preference.copyWith(
        apiSources: sources,
        activeApiSourceId: activeId,
      ),
    );
  }

  Future<void> setActiveApiSource(String sourceId) async {
    final exists = _preference.apiSources.any((item) => item.id == sourceId);
    if (!exists) {
      return;
    }
    await _savePreference(_preference.copyWith(activeApiSourceId: sourceId));
  }

  Future<void> resetAll() async {
    _studentInfo = null;
    _preference = UserPreference.empty();
    await _storageService.resetAll();
    notifyListeners();
  }

  Future<void> _savePreference(UserPreference nextPreference) async {
    _preference = nextPreference;
    await _storageService.savePreference(_preference);
    notifyListeners();
  }

  double _clampWeight(double value) {
    if (value < -0.5) {
      return -0.5;
    }
    if (value > 0.5) {
      return 0.5;
    }
    return value;
  }
}
