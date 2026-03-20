import 'package:flutter/widgets.dart';

import '../utils/constants.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(localizations != null, 'AppLocalizations not found in context');
    return localizations!;
  }

  static const Map<String, Map<String, String>> _strings =
      <String, Map<String, String>>{
    'zh': <String, String>{
      'appName': 'UniFlow 校园通知',
      'settings': '设置',
      'update': '更新',
      'dataSources': '数据源',
      'weights': '权重',
      'general': '通用',
      'about': '关于',
      'updateFrequency': '更新频率',
      'updateFrequencyDesc':
          '-1 表示不自动更新；启用后会在应用运行期间按固定分钟间隔自动刷新。',
      'autoUpdateFrequency': '自动更新频率',
      'noAutoUpdate': '不自动更新 (-1)',
      'minutesSuffix': '分钟',
      'disabledAutoUpdate': '已关闭自动更新',
      'updatedAutoUpdate': '自动更新频率已更新',
      'currentDataSource': '当前数据源',
      'refreshNow': '立即更新通知',
      'manualRefreshDone': '手动更新完成',
      'manualRefreshFailed': '手动更新失败',
      'apiSourcesDesc': '可维护多个 API 数据源，并在它们之间切换。高亮卡片表示当前启用的数据源。',
      'add': '添加',
      'currentSource': '当前使用',
      'edit': '编辑',
      'delete': '删除',
      'manualWeightSettings': '手动权重设置',
      'manualWeightDesc': '可为每个通知类型设置自定义权重，允许范围为 -0.5 到 0.5。',
      'manualInput': '手动输入',
      'homeSortStandard': '首页排序标准',
      'defaultSortMode': '默认排序方式',
      'updatedSortMode': '首页排序方式已更新',
      'languageSettings': '语言设置',
      'appLanguage': '应用语言',
      'followSystem': '跟随系统',
      'simplifiedChinese': '简体中文',
      'english': 'English',
      'languageSaved': '语言设置已保存',
      'appearanceSettings': '外观设置',
      'themeMode': '主题模式',
      'themeModeSaved': '主题模式已更新',
      'themePreset': '配色方案',
      'themePresetSaved': '配色方案已更新',
      'customThemeColor': '自定义主题色',
      'customThemeColorHint': '输入十六进制颜色，例如 #8D1F24',
      'customThemeColorSaved': '自定义主题色已更新',
      'clearCustomThemeColor': '恢复预设配色',
      'themeSystem': '跟随系统',
      'themeLight': '浅色模式',
      'themeDark': '深色模式',
      'presetXjtuRed': '交大红',
      'presetOceanBlue': '海湾蓝',
      'presetForestGreen': '森林绿',
      'presetAmberGold': '琥珀金',
      'supportProject': '支持项目',
      'supportProjectDesc': '如果这个项目对你有帮助，可以通过下面的方式支持持续开发。',
      'buyMeCoffee': 'Buy Me a Coffee',
      'afdian': '爱发电',
      'openSupportLinkFailed': '支持链接打开失败',
      'timelineView': '时间线',
      'noticeView': '通知',
      'timelineRange': '时间范围',
      'timelineRangeSaved': '默认时间范围已更新',
      'timelineRangeWeek': '近 7 天',
      'timelineRangeMonth': '近 30 天',
      'timelineRangeQuarter': '近 90 天',
      'calendarEmpty': '当前时间范围内没有通知',
      'calendarNoEvents': '当天没有通知',
      'calendarEventsTitle': '{value} 的通知',
      'settingsDisplayMode': '设置页显示方式',
      'settingsDisplayModeSaved': '设置页显示方式已更新',
      'layoutHorizontalTabs': '横向选项卡',
      'layoutVerticalTabs': '竖向选项卡',
      'layoutSecondaryMenu': '二级菜单',
      'timelinePeriod': '时间线默认范围',
      'choose': '选择',
      'blockedTypes': '已屏蔽类型',
      'noBlockedTypes': '当前没有屏蔽任何通知类型。',
      'dataManagement': '数据管理',
      'clearCache': '清除本地通知缓存',
      'cacheCleared': '本地通知缓存已清除',
      'resetAllSettings': '重置所有设置',
      'resetAllSettingsConfirm':
          '这会清空通知缓存、个人信息、已读状态和个性化偏好，确认继续吗？',
      'allSettingsReset': '所有设置已重置',
      'developerInfo': '开发者信息',
      'personalInfo': '个人信息',
      'sortMode': '排序方式',
      'currentSortMode': '当前排序：{value}',
      'personalInfoHint': '完善个人信息后，通知将按学院、书院、年级与专业进行个性化排序。',
      'message': '提示：{value}',
      'loadingNotices': '正在加载校园通知...',
      'loadFailed': '加载失败',
      'noNotice': '当前没有可展示的通知',
      'allFiltered': '所有通知类型都被过滤了，请到设置页恢复。',
      'updatedNotices': '通知已更新',
      'refreshFailed': '刷新失败，请稍后再试',
      'loadMoreFailed': '加载更多失败',
      'dislikeNoticeTitle': '屏蔽此类通知？',
      'dislikeNoticeContent': '后续“{value}”类型通知将从首页隐藏，可在设置页恢复。',
      'cancel': '取消',
      'confirmBlock': '确认屏蔽',
      'genreBlocked': '已屏蔽 {value} 通知',
      'sortPersonalized': '个性化排序',
      'sortLatest': '最新发布',
      'sortImportance': '重要度',
      'sortDeadline': '截止时间',
      'switchedSort': '已切换为 {value}',
      'noticeDetail': '通知详情',
      'noticeDetailMissing': '通知参数缺失，暂时无法展示详情。',
      'viewOriginal': '查看原文',
      'openOriginalFailed': '原文链接打开失败',
      'importance': '重要度 {value}',
      'expired': '已过期',
      'ongoing': '进行中',
      'summary': '摘要：{value}',
      'publishedAt': '发布时间：{value}',
      'fetchedAt': '抓取时间：{value}',
      'keywords': '关键词：{value}',
      'noticeBody': '通知正文',
      'emptyBodyHtml': '<p>暂无正文内容</p>',
      'openBodyLinkFailed': '正文链接打开失败',
      'timeline': '时间线',
      'attachments': '附件列表',
      'noAttachments': '暂无附件',
      'openAttachmentFailed': '附件链接打开失败',
      'entryYear': '入学年份',
      'entryYearHint': '例如 2023',
      'college': '所属学院',
      'academy': '所属书院',
      'major': '所学专业',
      'majorHint': '例如 人工智能',
      'gradeYear': '年级阶段',
      'saveInfo': '保存信息',
      'infoSaved': '个人信息已保存并立即生效',
      'entryYearRequired': '请输入入学年份',
      'entryYearInvalid': '入学年份必须是 4 位数字',
      'collegeRequired': '请选择所属学院',
      'academyRequired': '请选择所属书院',
      'majorRequired': '请输入专业名称',
      'gradeYearRequired': '请选择年级阶段',
      'notInterested': '不感兴趣',
      'read': '已读',
      'retryLoad': '重新加载',
      'unknownTime': '未知时间',
      'unnamedSource': '未命名数据源',
      'usingMockData': '使用内置 Mock 数据',
      'builtinMock': '内置 Mock 数据',
      'addApiSource': '添加 API 源',
      'editApiSource': '编辑 API 源',
      'name': '名称',
      'baseUrl': 'Base URL',
      'noticePath': '通知路径',
      'useMockData': '使用 Mock 数据',
      'save': '保存',
      'addedApiSourceMessage': '已添加 API 源 {value}',
      'updatedApiSourceMessage': '已更新 API 源 {value}',
      'removedApiSourceMessage': '已移除 {value}',
      'switchedApiSourceMessage': '已切换到 {value}',
      'setGenreWeight': '设置 {value} 权重',
      'weightHint': '输入 -0.5 到 0.5 之间的数值',
      'updatedGenreWeight': '{value} 权重已更新',
      'restoredGenre': '已恢复 {value} 通知',
      'version': '版本：{value}',
      'maintainer': '维护者：{value}',
      'contact': '联系：{value}',
      'noTitle': '无标题',
      'noSummary': '暂无摘要',
      'defaultKeywords': '#通知;#校园;#其他',
      'publishedLabel': '发布时间',
    },
    'en': <String, String>{
      'appName': 'UniFlow Campus Notices',
      'settings': 'Settings',
      'update': 'Update',
      'dataSources': 'Sources',
      'weights': 'Weights',
      'general': 'General',
      'about': 'About',
      'updateFrequency': 'Update Frequency',
      'updateFrequencyDesc':
          '-1 disables auto refresh. When enabled, notices refresh on a fixed minute interval while the app is running.',
      'autoUpdateFrequency': 'Auto Refresh Interval',
      'noAutoUpdate': 'Disabled (-1)',
      'minutesSuffix': 'minutes',
      'disabledAutoUpdate': 'Auto refresh disabled',
      'updatedAutoUpdate': 'Auto refresh interval updated',
      'currentDataSource': 'Current Data Source',
      'refreshNow': 'Refresh Notices Now',
      'manualRefreshDone': 'Manual refresh completed',
      'manualRefreshFailed': 'Manual refresh failed',
      'apiSourcesDesc':
          'Maintain multiple data sources and switch between them. The highlighted card is currently active.',
      'add': 'Add',
      'currentSource': 'Active',
      'edit': 'Edit',
      'delete': 'Delete',
      'manualWeightSettings': 'Manual Weight Settings',
      'manualWeightDesc': 'Enter a custom weight for each notice type. Allowed range is -0.5 to 0.5.',
      'manualInput': 'Manual Input',
      'homeSortStandard': 'Home Sorting',
      'defaultSortMode': 'Default Sort Mode',
      'updatedSortMode': 'Home sort mode updated',
      'languageSettings': 'Language',
      'appLanguage': 'App Language',
      'followSystem': 'Follow System',
      'simplifiedChinese': 'Simplified Chinese',
      'english': 'English',
      'languageSaved': 'Language setting saved',
      'appearanceSettings': 'Appearance',
      'themeMode': 'Theme Mode',
      'themeModeSaved': 'Theme mode updated',
      'themePreset': 'Color Scheme',
      'themePresetSaved': 'Color scheme updated',
      'customThemeColor': 'Custom Theme Color',
      'customThemeColorHint': 'Enter a hex color, for example #8D1F24',
      'customThemeColorSaved': 'Custom theme color updated',
      'clearCustomThemeColor': 'Use preset colors',
      'themeSystem': 'Follow System',
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'presetXjtuRed': 'XJTU Red',
      'presetOceanBlue': 'Ocean Blue',
      'presetForestGreen': 'Forest Green',
      'presetAmberGold': 'Amber Gold',
      'supportProject': 'Support the Project',
      'supportProjectDesc':
          'If this app helps you, you can support ongoing development with the buttons below.',
      'buyMeCoffee': 'Buy Me a Coffee',
      'afdian': 'Afdian',
      'openSupportLinkFailed': 'Failed to open support link',
      'timelineView': 'Timeline',
      'noticeView': 'Notices',
      'timelineRange': 'Time Range',
      'timelineRangeSaved': 'Default timeline range updated',
      'timelineRangeWeek': 'Last 7 Days',
      'timelineRangeMonth': 'Last 30 Days',
      'timelineRangeQuarter': 'Last 90 Days',
      'calendarEmpty': 'No notices in the selected range',
      'calendarNoEvents': 'No notices on this day',
      'calendarEventsTitle': 'Notices on {value}',
      'settingsDisplayMode': 'Settings Layout',
      'settingsDisplayModeSaved': 'Settings layout updated',
      'layoutHorizontalTabs': 'Horizontal Tabs',
      'layoutVerticalTabs': 'Vertical Tabs',
      'layoutSecondaryMenu': 'Secondary Menu',
      'timelinePeriod': 'Default Timeline Range',
      'choose': 'Choose',
      'blockedTypes': 'Blocked Types',
      'noBlockedTypes': 'No notice types are currently blocked.',
      'dataManagement': 'Data Management',
      'clearCache': 'Clear Local Cache',
      'cacheCleared': 'Local notice cache cleared',
      'resetAllSettings': 'Reset All Settings',
      'resetAllSettingsConfirm':
          'This will clear cached notices, personal info, read state, and personalization preferences. Continue?',
      'allSettingsReset': 'All settings have been reset',
      'developerInfo': 'Developer Info',
      'personalInfo': 'Profile',
      'sortMode': 'Sort',
      'currentSortMode': 'Current sort: {value}',
      'personalInfoHint':
          'Complete your personal info to enable personalized ranking by college, academy, grade, and major.',
      'message': 'Tip: {value}',
      'loadingNotices': 'Loading campus notices...',
      'loadFailed': 'Load failed',
      'noNotice': 'No notices are available right now',
      'allFiltered': 'All notice types are filtered out. Restore them in Settings.',
      'updatedNotices': 'Notices updated',
      'refreshFailed': 'Refresh failed, please try again later',
      'loadMoreFailed': 'Failed to load more',
      'dislikeNoticeTitle': 'Block this notice type?',
      'dislikeNoticeContent':
          'Future notices of type "{value}" will be hidden from the home list. You can restore them in Settings.',
      'cancel': 'Cancel',
      'confirmBlock': 'Block',
      'genreBlocked': '{value} notices blocked',
      'sortPersonalized': 'Personalized',
      'sortLatest': 'Latest',
      'sortImportance': 'Importance',
      'sortDeadline': 'Deadline',
      'switchedSort': 'Switched to {value}',
      'noticeDetail': 'Notice Details',
      'noticeDetailMissing': 'Notice arguments are missing, so details cannot be shown.',
      'viewOriginal': 'Open Original',
      'openOriginalFailed': 'Failed to open original link',
      'importance': 'Importance {value}',
      'expired': 'Expired',
      'ongoing': 'Active',
      'summary': 'Summary: {value}',
      'publishedAt': 'Published: {value}',
      'fetchedAt': 'Fetched: {value}',
      'keywords': 'Keywords: {value}',
      'noticeBody': 'Notice Body',
      'emptyBodyHtml': '<p>No body content</p>',
      'openBodyLinkFailed': 'Failed to open body link',
      'timeline': 'Timeline',
      'attachments': 'Attachments',
      'noAttachments': 'No attachments',
      'openAttachmentFailed': 'Failed to open attachment link',
      'entryYear': 'Enrollment Year',
      'entryYearHint': 'For example 2023',
      'college': 'College',
      'academy': 'Academy',
      'major': 'Major',
      'majorHint': 'For example Artificial Intelligence',
      'gradeYear': 'Grade Level',
      'saveInfo': 'Save Info',
      'infoSaved': 'Personal info saved and applied immediately',
      'entryYearRequired': 'Please enter your enrollment year',
      'entryYearInvalid': 'Enrollment year must be 4 digits',
      'collegeRequired': 'Please select your college',
      'academyRequired': 'Please select your academy',
      'majorRequired': 'Please enter your major',
      'gradeYearRequired': 'Please select your grade level',
      'notInterested': 'Not Interested',
      'read': 'Read',
      'retryLoad': 'Retry',
      'unknownTime': 'Unknown time',
      'unnamedSource': 'Unnamed source',
      'usingMockData': 'Using built-in mock data',
      'builtinMock': 'Built-in Mock Data',
      'addApiSource': 'Add API Source',
      'editApiSource': 'Edit API Source',
      'name': 'Name',
      'baseUrl': 'Base URL',
      'noticePath': 'Notice Path',
      'useMockData': 'Use Mock Data',
      'save': 'Save',
      'addedApiSourceMessage': 'Added API source {value}',
      'updatedApiSourceMessage': 'Updated API source {value}',
      'removedApiSourceMessage': 'Removed {value}',
      'switchedApiSourceMessage': 'Switched to {value}',
      'setGenreWeight': 'Set weight for {value}',
      'weightHint': 'Enter a value between -0.5 and 0.5',
      'updatedGenreWeight': '{value} weight updated',
      'restoredGenre': '{value} notices restored',
      'version': 'Version: {value}',
      'maintainer': 'Maintainer: {value}',
      'contact': 'Contact: {value}',
      'noTitle': 'Untitled',
      'noSummary': 'No summary',
      'defaultKeywords': '#notice;#campus;#other',
      'publishedLabel': 'Published',
    },
  };

  bool get _isEnglish => locale.languageCode.toLowerCase().startsWith('en');

  String _value(String key) {
    final language = _isEnglish ? 'en' : 'zh';
    return _strings[language]?[key] ?? key;
  }

  String _format(String key, String value) {
    return _value(key).replaceAll('{value}', value);
  }

  String get appName => _value('appName');
  String get settings => _value('settings');
  String get update => _value('update');
  String get dataSources => _value('dataSources');
  String get weights => _value('weights');
  String get general => _value('general');
  String get about => _value('about');
  String get updateFrequency => _value('updateFrequency');
  String get updateFrequencyDesc => _value('updateFrequencyDesc');
  String get autoUpdateFrequency => _value('autoUpdateFrequency');
  String get noAutoUpdate => _value('noAutoUpdate');
  String minutesLabel(int value) => '$value ${_value('minutesSuffix')}';
  String get disabledAutoUpdate => _value('disabledAutoUpdate');
  String get updatedAutoUpdate => _value('updatedAutoUpdate');
  String get currentDataSource => _value('currentDataSource');
  String get refreshNow => _value('refreshNow');
  String get manualRefreshDone => _value('manualRefreshDone');
  String get manualRefreshFailed => _value('manualRefreshFailed');
  String get apiSourcesDesc => _value('apiSourcesDesc');
  String get add => _value('add');
  String get currentSource => _value('currentSource');
  String get edit => _value('edit');
  String get delete => _value('delete');
  String get manualWeightSettings => _value('manualWeightSettings');
  String get manualWeightDesc => _value('manualWeightDesc');
  String get manualInput => _value('manualInput');
  String get homeSortStandard => _value('homeSortStandard');
  String get defaultSortMode => _value('defaultSortMode');
  String get updatedSortMode => _value('updatedSortMode');
  String get languageSettings => _value('languageSettings');
  String get appLanguage => _value('appLanguage');
  String get languageSaved => _value('languageSaved');
  String get appearanceSettings => _value('appearanceSettings');
  String get themeMode => _value('themeMode');
  String get themeModeSaved => _value('themeModeSaved');
  String get themePreset => _value('themePreset');
  String get themePresetSaved => _value('themePresetSaved');
  String get customThemeColor => _value('customThemeColor');
  String get customThemeColorHint => _value('customThemeColorHint');
  String get customThemeColorSaved => _value('customThemeColorSaved');
  String get clearCustomThemeColor => _value('clearCustomThemeColor');
  String get blockedTypes => _value('blockedTypes');
  String get noBlockedTypes => _value('noBlockedTypes');
  String restoredGenre(String value) => _format('restoredGenre', value);
  String get dataManagement => _value('dataManagement');
  String get clearCache => _value('clearCache');
  String get cacheCleared => _value('cacheCleared');
  String get resetAllSettings => _value('resetAllSettings');
  String get resetAllSettingsConfirm => _value('resetAllSettingsConfirm');
  String get allSettingsReset => _value('allSettingsReset');
  String get personalInfo => _value('personalInfo');

  String sortModeLabel(String mode) {
    switch (mode) {
      case AppSortModes.latest:
        return _value('sortLatest');
      case AppSortModes.importance:
        return _value('sortImportance');
      case AppSortModes.deadline:
        return _value('sortDeadline');
      case AppSortModes.personalized:
      default:
        return _value('sortPersonalized');
    }
  }

  String languageLabel(String code) {
    switch (code) {
      case AppLanguageOptions.zhCn:
        return _value('simplifiedChinese');
      case AppLanguageOptions.enUs:
        return _value('english');
      case AppLanguageOptions.system:
      default:
        return _value('followSystem');
    }
  }

  String themeModeLabel(String mode) {
    switch (mode) {
      case AppThemeModes.light:
        return _value('themeLight');
      case AppThemeModes.dark:
        return _value('themeDark');
      case AppThemeModes.system:
      default:
        return _value('themeSystem');
    }
  }

  String themePresetLabel(String preset) {
    switch (preset) {
      case AppThemePresets.oceanBlue:
        return _value('presetOceanBlue');
      case AppThemePresets.forestGreen:
        return _value('presetForestGreen');
      case AppThemePresets.amberGold:
        return _value('presetAmberGold');
      case AppThemePresets.xjtuRed:
      default:
        return _value('presetXjtuRed');
    }
  }

  String timelineRangeLabel(String value) {
    switch (value) {
      case AppTimelineRanges.week:
        return _value('timelineRangeWeek');
      case AppTimelineRanges.quarter:
        return _value('timelineRangeQuarter');
      case AppTimelineRanges.month:
      default:
        return _value('timelineRangeMonth');
    }
  }

  String settingsLayoutLabel(String value) {
    switch (value) {
      case AppSettingsLayouts.verticalTabs:
        return _value('layoutVerticalTabs');
      case AppSettingsLayouts.secondaryMenu:
        return _value('layoutSecondaryMenu');
      case AppSettingsLayouts.horizontalTabs:
      default:
        return _value('layoutHorizontalTabs');
    }
  }

  String get sortMode => _value('sortMode');
  String currentSortMode(String value) => _format('currentSortMode', value);
  String get personalInfoHint => _value('personalInfoHint');
  String message(String value) => _format('message', value);
  String get loadingNotices => _value('loadingNotices');
  String get loadFailed => _value('loadFailed');
  String get noNotice => _value('noNotice');
  String get allFiltered => _value('allFiltered');
  String get updatedNotices => _value('updatedNotices');
  String get refreshFailed => _value('refreshFailed');
  String get loadMoreFailed => _value('loadMoreFailed');
  String get dislikeNoticeTitle => _value('dislikeNoticeTitle');
  String dislikeNoticeContent(String value) => _format('dislikeNoticeContent', value);
  String get cancel => _value('cancel');
  String get confirmBlock => _value('confirmBlock');
  String genreBlocked(String value) => _format('genreBlocked', value);
  String switchedSort(String value) => _format('switchedSort', value);
  String get noticeDetail => _value('noticeDetail');
  String get noticeDetailMissing => _value('noticeDetailMissing');
  String get viewOriginal => _value('viewOriginal');
  String get openOriginalFailed => _value('openOriginalFailed');
  String importance(String value) => _format('importance', value);
  String get expired => _value('expired');
  String get ongoing => _value('ongoing');
  String summary(String value) => _format('summary', value);
  String publishedAt(String value) => _format('publishedAt', value);
  String fetchedAt(String value) => _format('fetchedAt', value);
  String keywords(String value) => _format('keywords', value);
  String get noticeBody => _value('noticeBody');
  String get emptyBodyHtml => _value('emptyBodyHtml');
  String get openBodyLinkFailed => _value('openBodyLinkFailed');
  String get timeline => _value('timeline');
  String get attachments => _value('attachments');
  String get noAttachments => _value('noAttachments');
  String get openAttachmentFailed => _value('openAttachmentFailed');
  String get entryYear => _value('entryYear');
  String get entryYearHint => _value('entryYearHint');
  String get college => _value('college');
  String get academy => _value('academy');
  String get major => _value('major');
  String get majorHint => _value('majorHint');
  String get gradeYear => _value('gradeYear');
  String get saveInfo => _value('saveInfo');
  String get infoSaved => _value('infoSaved');
  String get entryYearRequired => _value('entryYearRequired');
  String get entryYearInvalid => _value('entryYearInvalid');
  String get collegeRequired => _value('collegeRequired');
  String get academyRequired => _value('academyRequired');
  String get majorRequired => _value('majorRequired');
  String get gradeYearRequired => _value('gradeYearRequired');
  String get notInterested => _value('notInterested');
  String get read => _value('read');
  String get retryLoad => _value('retryLoad');
  String get noticeView => _value('noticeView');
  String get timelineView => _value('timelineView');
  String get timelineRange => _value('timelineRange');
  String get timelineRangeSaved => _value('timelineRangeSaved');
  String get calendarEmpty => _value('calendarEmpty');
  String get calendarNoEvents => _value('calendarNoEvents');
  String calendarEventsTitle(String value) => _format('calendarEventsTitle', value);
  String get settingsDisplayMode => _value('settingsDisplayMode');
  String get settingsDisplayModeSaved => _value('settingsDisplayModeSaved');
  String get timelinePeriod => _value('timelinePeriod');
  String get choose => _value('choose');
  String get unknownTime => _value('unknownTime');
  String get unnamedSource => _value('unnamedSource');
  String get usingMockData => _value('usingMockData');
  String get builtinMock => _value('builtinMock');
  String get addApiSource => _value('addApiSource');
  String get editApiSource => _value('editApiSource');
  String get name => _value('name');
  String get baseUrl => _value('baseUrl');
  String get noticePath => _value('noticePath');
  String get useMockData => _value('useMockData');
  String get save => _value('save');
  String get supportProject => _value('supportProject');
  String get supportProjectDesc => _value('supportProjectDesc');
  String get buyMeCoffee => _value('buyMeCoffee');
  String get afdian => _value('afdian');
  String get openSupportLinkFailed => _value('openSupportLinkFailed');
  String addedApiSourceMessage(String value) => _format('addedApiSourceMessage', value);
  String updatedApiSourceMessage(String value) => _format('updatedApiSourceMessage', value);
  String removedApiSourceMessage(String value) => _format('removedApiSourceMessage', value);
  String switchedApiSourceMessage(String value) => _format('switchedApiSourceMessage', value);
  String setGenreWeight(String value) => _format('setGenreWeight', value);
  String get weightHint => _value('weightHint');
  String updatedGenreWeight(String value) => _format('updatedGenreWeight', value);
  String version(String value) => _format('version', value);
  String maintainer(String value) => _format('maintainer', value);
  String contact(String value) => _format('contact', value);
  String get noTitle => _value('noTitle');
  String get noSummary => _value('noSummary');
  String get defaultKeywords => _value('defaultKeywords');
  String get publishedLabel => _value('publishedLabel');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => <String>['zh', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
