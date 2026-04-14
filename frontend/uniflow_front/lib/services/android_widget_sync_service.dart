import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/notice_model.dart';
import '../models/user_preference.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class AndroidWidgetSyncService {
  static const MethodChannel _channel =
      MethodChannel('uniflow/android_widgets');

  Timer? _debounceTimer;

  void scheduleSync({
    required List<NoticeModel> notices,
    required UserPreference preference,
  }) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final snapshotNotices = List<NoticeModel>.from(notices.take(4));
    final snapshotPreference = preference;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 220),
      () async {
        final payload = _buildPayload(
          notices: snapshotNotices,
          preference: snapshotPreference,
        );
        try {
          await _channel.invokeMethod<void>(
            'syncWidgets',
            <String, dynamic>{
              'payload': jsonEncode(payload),
            },
          );
        } catch (_) {
          // Keep widget sync best-effort so UI state changes never fail on platform issues.
        }
      },
    );
  }

  void dispose() {
    _debounceTimer?.cancel();
  }

  Map<String, dynamic> _buildPayload({
    required List<NoticeModel> notices,
    required UserPreference preference,
  }) {
    return <String, dynamic>{
      'updatedAtLabel': AppDateUtils.formatDateTime(DateTime.now()),
      'listSize': preference.widgetListSize,
      'timelineSize': preference.widgetTimelineSize,
      'listVisibleCount': _listVisibleCount(preference.widgetListSize),
      'timelineVisibleCount': _timelineVisibleCount(
        preference.widgetTimelineSize,
      ),
      'notices': notices.map(_noticeToJson).toList(),
    };
  }

  Map<String, dynamic> _noticeToJson(NoticeModel notice) {
    final publishedTime = AppDateUtils.extractPublishedTime(notice);
    final businessTime =
        AppDateUtils.extractLatestBusinessTime(notice) ?? publishedTime;
    return <String, dynamic>{
      'id': notice.id,
      'title': notice.title,
      'source': notice.source,
      'genre': notice.genre,
      'review': notice.review,
      'publishedTimeLabel': AppDateUtils.formatDateTime(publishedTime),
      'businessTimeLabel': AppDateUtils.formatDateTime(businessTime),
      'isExpired': AppDateUtils.isExpired(notice),
    };
  }

  int _listVisibleCount(String size) {
    switch (size) {
      case AppWidgetSizes.small:
        return 2;
      case AppWidgetSizes.large:
        return 4;
      case AppWidgetSizes.medium:
      default:
        return 3;
    }
  }

  int _timelineVisibleCount(String size) {
    switch (size) {
      case AppWidgetSizes.small:
        return 2;
      case AppWidgetSizes.large:
      case AppWidgetSizes.medium:
      default:
        return 3;
    }
  }
}
