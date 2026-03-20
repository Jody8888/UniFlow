import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/notice_model.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class TimelineCalendar extends StatelessWidget {
  const TimelineCalendar({
    super.key,
    required this.notices,
    required this.selectedRange,
    required this.onRangeChanged,
    required this.onNoticeTap,
    required this.favoriteIds,
    required this.onToggleFavorite,
  });

  final List<NoticeModel> notices;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;
  final Future<void> Function(NoticeModel notice) onNoticeTap;
  final Set<String> favoriteIds;
  final Future<void> Function(NoticeModel notice) onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final start = _normalizeDate(DateTime.now());
    final end = start.add(
      Duration(days: AppTimelineRanges.daysFor(selectedRange) - 1),
    );
    final buckets = _buildBuckets(start, end);
    final calendarDays = _buildCalendarDays(start, end);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      children: [
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: AppTimelineRanges.values.map((value) {
            final selected = value == selectedRange;
            return ChoiceChip(
              label: Text(l10n.timelineRangeLabel(value)),
              selected: selected,
              onSelected: (_) => onRangeChanged(value),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.medium),
        if (buckets.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.large),
            child: Center(child: Text(l10n.calendarEmpty)),
          )
        else ...[
          _WeekHeader(start: start),
          const SizedBox(height: AppSpacing.small),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: calendarDays.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: AppSpacing.small,
              crossAxisSpacing: AppSpacing.small,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final date = calendarDays[index];
              final inRange =
                  !date.isBefore(start) && !date.isAfter(end);
              final dayNotices = buckets[_dateKey(date)] ?? <NoticeModel>[];
              return _CalendarCell(
                date: date,
                inRange: inRange,
                notices: dayNotices,
                onTap: dayNotices.isEmpty
                    ? null
                    : () => _openDaySheet(context, date, dayNotices),
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _openDaySheet(
    BuildContext context,
    DateTime date,
    List<NoticeModel> notices,
  ) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.calendarEventsTitle(
                    AppDateUtils.formatDateTime(date).split(' ').first,
                  ),
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.small),
                if (notices.isEmpty)
                  Text(l10n.calendarNoEvents)
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: notices.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.small),
                      itemBuilder: (_, index) {
                        final notice = notices[index];
                        return Card(
                          child: ListTile(
                            title: Text(notice.title, maxLines: 2),
                            subtitle: Text(
                              '${notice.source} · ${AppDateUtils.formatTimeAgo(AppDateUtils.extractPublishedTime(notice))}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(notice.genre),
                                IconButton(
                                  tooltip: favoriteIds.contains(notice.id)
                                      ? context.l10n.removeFromFavorites
                                      : context.l10n.addToFavorites,
                                  onPressed: () async {
                                    await onToggleFavorite(notice);
                                    if (sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop();
                                    }
                                  },
                                  icon: Icon(
                                    favoriteIds.contains(notice.id)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: favoriteIds.contains(notice.id)
                                        ? Colors.amber.shade700
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              Navigator.of(sheetContext).pop();
                              await onNoticeTap(notice);
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, List<NoticeModel>> _buildBuckets(DateTime start, DateTime end) {
    final buckets = <String, List<NoticeModel>>{};
    for (final notice in notices) {
      final date = _resolveNoticeDate(notice);
      if (date == null) {
        continue;
      }
      final normalized = _normalizeDate(date);
      if (normalized.isBefore(start) || normalized.isAfter(end)) {
        continue;
      }
      final key = _dateKey(normalized);
      buckets.putIfAbsent(key, () => <NoticeModel>[]).add(notice);
    }
    return buckets;
  }

  List<DateTime> _buildCalendarDays(DateTime start, DateTime end) {
    final gridStart = start.subtract(Duration(days: start.weekday - 1));
    final gridEnd = end.add(Duration(days: DateTime.daysPerWeek - end.weekday));
    final days = <DateTime>[];
    for (
      var date = gridStart;
      !date.isAfter(gridEnd);
      date = date.add(const Duration(days: 1))
    ) {
      days.add(date);
    }
    return days;
  }

  DateTime? _resolveNoticeDate(NoticeModel notice) {
    return AppDateUtils.extractLatestBusinessTime(notice) ??
        AppDateUtils.extractPublishedTime(notice);
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.start});

  final DateTime start;

  @override
  Widget build(BuildContext context) {
    final labels = List<String>.generate(
      DateTime.daysPerWeek,
      (index) {
        final date = start.subtract(Duration(days: start.weekday - 1 - index));
        return MaterialLocalizations.of(context).narrowWeekdays[date.weekday % 7];
      },
    );
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.date,
    required this.inRange,
    required this.notices,
    required this.onTap,
  });

  final DateTime date;
  final bool inRange;
  final List<NoticeModel> notices;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.small),
        decoration: BoxDecoration(
          color: !inRange
              ? colorScheme.surfaceContainerLowest
              : notices.isEmpty
                  ? colorScheme.surfaceContainerLow
                  : colorScheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppRadii.medium),
          border: Border.all(
            color: notices.isEmpty
                ? colorScheme.outlineVariant
                : colorScheme.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: inRange
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                ),
                const Spacer(),
                if (notices.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${notices.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ...notices.take(2).map(
              (notice) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  notice.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            if (notices.length > 2)
              Text(
                '+${notices.length - 2}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
