import 'dart:io';

import 'package:add_2_calendar/add_2_calendar.dart' as native_calendar;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/notice_model.dart';
import '../utils/date_utils.dart';

class CalendarService {
  Future<String> exportNoticesAsIcs(List<NoticeModel> notices) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/uniflow_favorites.ics');
    await file.writeAsString(_buildIcs(notices));
    return file.path;
  }

  Future<void> shareIcsFile(String path) async {
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(path)],
        text: 'UniFlow Favorites',
      ),
    );
  }

  Future<void> importToSystemCalendar(List<NoticeModel> notices) async {
    for (final notice in notices) {
      final event = _buildEvent(notice);
      await native_calendar.Add2Calendar.addEvent2Cal(event);
    }
  }

  String previewEvent(NoticeModel notice) {
    final event = _resolveEventData(notice);
    return [
      'BEGIN:VEVENT',
      'SUMMARY:${_escape(event.title)}',
      'DESCRIPTION:${_escape(event.description)}',
      'LOCATION:${_escape(event.location)}',
      'DTSTART:${_formatUtc(event.startDate)}',
      'DTEND:${_formatUtc(event.endDate)}',
      'END:VEVENT',
    ].join('\n');
  }

  String _buildIcs(List<NoticeModel> notices) {
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//UniFlow//Campus Notices//CN')
      ..writeln('CALSCALE:GREGORIAN');

    for (final notice in notices) {
      final event = _resolveEventData(notice);
      buffer
        ..writeln('BEGIN:VEVENT')
        ..writeln('UID:${notice.id}@uniflow')
        ..writeln('DTSTAMP:${_formatUtc(DateTime.now())}')
        ..writeln('DTSTART:${_formatUtc(event.startDate)}')
        ..writeln('DTEND:${_formatUtc(event.endDate)}')
        ..writeln('SUMMARY:${_escape(event.title)}')
        ..writeln('DESCRIPTION:${_escape(event.description)}')
        ..writeln('LOCATION:${_escape(event.location)}')
        ..writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  native_calendar.Event _buildEvent(NoticeModel notice) {
    final event = _resolveEventData(notice);
    return native_calendar.Event(
      title: event.title,
      description: event.description,
      location: event.location,
      startDate: event.startDate,
      endDate: event.endDate,
    );
  }

  _ResolvedCalendarEvent _resolveEventData(NoticeModel notice) {
    final published = AppDateUtils.extractPublishedTime(notice) ?? DateTime.now();
    final business = AppDateUtils.extractLatestBusinessTime(notice);
    final timelineStart = AppDateUtils.extractEarliestBusinessTime(notice);
    final start = timelineStart ?? published;
    var end = business ?? start.add(const Duration(hours: 1));
    if (!end.isAfter(start)) {
      end = start.add(const Duration(hours: 1));
    }

    return _ResolvedCalendarEvent(
      title: notice.title,
      description: _buildDescription(notice),
      location: notice.source,
      startDate: start,
      endDate: end,
    );
  }

  String _buildDescription(NoticeModel notice) {
    final lines = <String>[
      notice.review,
      if (notice.link.trim().isNotEmpty) 'Link: ${notice.link.trim()}',
    ];
    return lines.where((item) => item.trim().isNotEmpty).join('\n');
  }

  String _formatUtc(DateTime dateTime) {
    return '${dateTime.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first}Z';
  }

  String _escape(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;')
        .replaceAll('\n', r'\n');
  }
}

class _ResolvedCalendarEvent {
  const _ResolvedCalendarEvent({
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.endDate,
  });

  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
}
