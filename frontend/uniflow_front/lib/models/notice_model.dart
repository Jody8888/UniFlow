import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../utils/constants.dart';

class NoticeModel {
  NoticeModel({
    required this.id,
    required this.title,
    required this.genre,
    required this.importance,
    required this.source,
    required this.review,
    required this.keywords,
    required this.timeline,
    required this.attachment,
    required this.originalText,
    required this.link,
    required this.fetchTime,
  });

  final String id;
  final String title;
  final String genre;
  final int importance;
  final String source;
  final String review;
  final String keywords;
  final List<Map<String, String>> timeline;
  final List<Map<String, String>> attachment;
  final String originalText;
  final String link;
  final String fetchTime;

  List<String> get keywordList {
    return keywords
        .split(';')
        .map((item) => item.trim().replaceFirst('#', ''))
        .where((item) => item.isNotEmpty)
        .toList();
  }

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    final idValue = _readString(json['uuid']) ?? _readString(json['id']);
    final fetchTimeValue =
        _readString(json['fetch_time']) ?? DateTime.now().toIso8601String();
    final genreValue = _readString(json['genre']);
    final sourceValue = _readString(json['source']);
    final timelineList = _normalizeMapList(json['timeline']);
    final normalizedTimeline = _sortTimeline(
      timelineList.isEmpty
          ? <Map<String, String>>[
              <String, String>{'发布时间': fetchTimeValue},
            ]
          : timelineList,
    );

    return NoticeModel(
      id: (idValue == null || idValue.trim().isEmpty)
          ? UniqueKey().toString()
          : idValue,
      title: _normalizeTitle(_readString(json['title'])),
      genre:
          AppConstants.noticeGenres.contains(genreValue) ? genreValue! : '其他',
      importance: _normalizeImportance(json['importance']),
      source: AppConstants.noticeSources.contains(sourceValue)
          ? sourceValue!
          : '其他',
      review: _normalizeReview(
        review: _readString(json['review']),
        originalText: _readString(json['original_text']),
      ),
      keywords: _normalizeKeywords(_readString(json['keywords'])),
      timeline: normalizedTimeline,
      attachment: _normalizeMapList(json['attachment']),
      originalText: _readString(json['original_text']) ?? '',
      link: _readString(json['link']) ?? '',
      fetchTime: fetchTimeValue,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'genre': genre,
      'importance': importance,
      'source': source,
      'review': review,
      'keywords': keywords,
      'timeline': timeline,
      'attachment': attachment,
      'original_text': originalText,
      'link': link,
      'fetch_time': fetchTime,
    };
  }

  static String _normalizeTitle(String? title) {
    final trimmed = title?.trim() ?? '';
    return trimmed.isEmpty ? '无标题' : trimmed;
  }

  static int _normalizeImportance(dynamic value) {
    final parsed =
        value is num ? value.round() : int.tryParse(value?.toString() ?? '');
    return _clampInt(parsed ?? 2, min: 0, max: 10);
  }

  static String _normalizeReview({
    required String? review,
    required String? originalText,
  }) {
    final trimmedReview = review?.trim() ?? '';
    if (trimmedReview.isNotEmpty) {
      return trimmedReview.length > 50
          ? trimmedReview.substring(0, 50)
          : trimmedReview;
    }

    final pureText = (originalText ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (pureText.isEmpty) {
      return '暂无摘要';
    }
    return pureText.length > 50 ? pureText.substring(0, 50) : pureText;
  }

  static String _normalizeKeywords(String? keywords) {
    final trimmed = keywords?.trim() ?? '';
    return trimmed.isEmpty ? '#通知;#校园;#其他' : trimmed;
  }

  static String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static List<Map<String, String>> _normalizeMapList(dynamic value) {
    if (value is! List) {
      return <Map<String, String>>[];
    }

    return value
        .whereType<Map>()
        .map((item) {
          final result = <String, String>{};
          for (final entry in item.entries) {
            final key = entry.key.toString().trim();
            final val = entry.value?.toString().trim() ?? '';
            if (key.isNotEmpty && val.isNotEmpty) {
              result[key] = val;
            }
          }
          return result;
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<Map<String, String>> _sortTimeline(
      List<Map<String, String>> timeline) {
    final copied = List<Map<String, String>>.from(timeline);
    copied.sort((left, right) {
      final leftTime =
          _parseDateTime(left.entries.first.value)?.millisecondsSinceEpoch ?? 0;
      final rightTime =
          _parseDateTime(right.entries.first.value)?.millisecondsSinceEpoch ??
              0;
      return leftTime.compareTo(rightTime);
    });
    return copied;
  }

  static DateTime? _parseDateTime(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }

    final direct = DateTime.tryParse(text);
    if (direct != null) {
      return direct;
    }

    final formats = <DateFormat>[
      DateFormat('yyyy-MM-dd HH:mm:ss'),
      DateFormat('yyyy-MM-dd HH:mm'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('yyyy/MM/dd HH:mm:ss'),
      DateFormat('yyyy/MM/dd HH:mm'),
      DateFormat('yyyy/MM/dd'),
    ];

    for (final format in formats) {
      try {
        return format.parseStrict(text);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static int _clampInt(int value, {required int min, required int max}) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}
