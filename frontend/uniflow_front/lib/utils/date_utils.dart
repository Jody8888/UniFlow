import 'package:intl/intl.dart';

import '../models/notice_model.dart';

class AppDateUtils {
  static const List<String> _businessKeywords = <String>[
    '截止',
    '结束',
    '举办',
    '报名',
    '提交',
    '考试',
    '核验',
    '预约',
    '补测',
    '路演',
    '检查',
  ];

  static DateTime? parseDateTime(String? raw) {
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

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '未知时间';
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  static List<Map<String, String>> sortTimeline(List<Map<String, String>> timeline) {
    final copied = List<Map<String, String>>.from(timeline);
    copied.sort((left, right) {
      final leftValue = parseDateTime(left.entries.first.value)?.millisecondsSinceEpoch ?? 0;
      final rightValue = parseDateTime(right.entries.first.value)?.millisecondsSinceEpoch ?? 0;
      return leftValue.compareTo(rightValue);
    });
    return copied;
  }

  static DateTime? extractPublishedTime(NoticeModel notice) {
    for (final item in notice.timeline) {
      for (final entry in item.entries) {
        if (entry.key.contains('发布')) {
          return parseDateTime(entry.value);
        }
      }
    }

    final sorted = sortTimeline(notice.timeline);
    if (sorted.isNotEmpty) {
      return parseDateTime(sorted.first.entries.first.value);
    }
    return parseDateTime(notice.fetchTime);
  }

  static DateTime? extractLatestBusinessTime(NoticeModel notice) {
    final candidates = <DateTime>[];
    for (final item in notice.timeline) {
      for (final entry in item.entries) {
        if (_businessKeywords.any((keyword) => entry.key.contains(keyword))) {
          final parsed = parseDateTime(entry.value);
          if (parsed != null) {
            candidates.add(parsed);
          }
        }
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort();
      return candidates.last;
    }

    final published = extractPublishedTime(notice);
    return published?.add(const Duration(days: 30));
  }

  static DateTime? extractEarliestBusinessTime(NoticeModel notice) {
    final candidates = <DateTime>[];
    for (final item in notice.timeline) {
      for (final entry in item.entries) {
        if (_businessKeywords.any((keyword) => entry.key.contains(keyword))) {
          final parsed = parseDateTime(entry.value);
          if (parsed != null) {
            candidates.add(parsed);
          }
        }
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort();
    return candidates.first;
  }

  static bool isExpired(NoticeModel notice) {
    final latestBusinessTime = extractLatestBusinessTime(notice);
    if (latestBusinessTime == null) {
      return false;
    }
    return latestBusinessTime.isBefore(DateTime.now());
  }
}
