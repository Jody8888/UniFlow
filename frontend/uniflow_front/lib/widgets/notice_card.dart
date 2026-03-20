import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/notice_model.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.notice,
    required this.isRead,
    required this.onTap,
    required this.onMarkDislike,
  });

  final NoticeModel notice;
  final bool isRead;
  final VoidCallback onTap;
  final VoidCallback onMarkDislike;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isExpired = AppDateUtils.isExpired(notice);
    final publishTime = AppDateUtils.extractPublishedTime(notice);
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = isRead
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface;
    final bodyColor = isRead
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: Card(
          color: isRead
              ? Theme.of(context).brightness == Brightness.dark
                  ? colorScheme.surfaceContainerHigh
                  : AppColors.readCard
              : Theme.of(context).cardTheme.color,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.large),
            onTap: onTap,
            onLongPress: onMarkDislike,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notice.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: titleColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      IconButton(
                        tooltip: l10n.notInterested,
                        onPressed: onMarkDislike,
                        icon: const Icon(Icons.more_horiz),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    notice.review,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: bodyColor,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: AppSpacing.small,
                    children: [
                      _InfoChip(
                        label: notice.genre,
                        backgroundColor: AppColors.genreChip,
                      ),
                      _InfoChip(
                        label: notice.source,
                        backgroundColor: AppColors.sourceChip,
                      ),
                      _InfoChip(
                        label: l10n.importance('${notice.importance}'),
                        backgroundColor: AppColors.importanceChip,
                      ),
                      if (isExpired)
                        _InfoChip(
                          label: l10n.expired,
                          backgroundColor: AppColors.expiredChip,
                        ),
                      if (isRead)
                        _InfoChip(
                          label: l10n.read,
                          backgroundColor: AppColors.readChip,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          AppDateUtils.formatDateTime(publishTime),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.backgroundColor,
  });

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
