import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/notice_model.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class DesktopWidgetPreview extends StatelessWidget {
  const DesktopWidgetPreview({
    super.key,
    required this.title,
    required this.mode,
    required this.size,
    required this.notices,
  });

  final String title;
  final String mode;
  final String size;
  final List<NoticeModel> notices;

  @override
  Widget build(BuildContext context) {
    final dimensions = _dimensionsFor(size);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.small),
            Container(
              width: dimensions.width,
              height: dimensions.height,
              padding: const EdgeInsets.all(AppSpacing.small),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadii.medium),
              ),
              child: mode == 'timeline'
                  ? _TimelineWidgetBody(notices: notices, size: size)
                  : _ListWidgetBody(notices: notices, size: size),
            ),
          ],
        ),
      ),
    );
  }

  Size _dimensionsFor(String value) {
    switch (value) {
      case AppWidgetSizes.small:
        return const Size(160, 160);
      case AppWidgetSizes.large:
        return const Size(320, 180);
      case AppWidgetSizes.medium:
      default:
        return const Size(240, 160);
    }
  }
}

class _ListWidgetBody extends StatelessWidget {
  const _ListWidgetBody({
    required this.notices,
    required this.size,
  });

  final List<NoticeModel> notices;
  final String size;

  @override
  Widget build(BuildContext context) {
    final visible = size == AppWidgetSizes.small ? 2 : size == AppWidgetSizes.medium ? 3 : 4;
    final items = notices.take(visible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.widgetListMode,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.small),
        ...items.map(
          (notice) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.star, size: 12, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    notice.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineWidgetBody extends StatelessWidget {
  const _TimelineWidgetBody({
    required this.notices,
    required this.size,
  });

  final List<NoticeModel> notices;
  final String size;

  @override
  Widget build(BuildContext context) {
    final visible = size == AppWidgetSizes.small ? 2 : 3;
    final items = notices.take(visible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.widgetTimelineMode,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.small),
        Expanded(
          child: Column(
            children: items.map((notice) {
              final time = AppDateUtils.extractLatestBusinessTime(notice) ??
                  AppDateUtils.extractPublishedTime(notice);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppDateUtils.formatDateTime(time),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              notice.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
