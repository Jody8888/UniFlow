import 'package:flutter/material.dart';

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
    final isExpired = AppDateUtils.isExpired(notice);
    final publishTime = AppDateUtils.extractPublishedTime(notice);
    return Card(
      color: isRead ? AppColors.readCard : Colors.white,
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
                            color: isRead
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  IconButton(
                    tooltip: '不感兴趣',
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
                      color: isRead
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
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
                    label: '重要度 ${notice.importance}',
                    backgroundColor: AppColors.importanceChip,
                  ),
                  if (isExpired)
                    const _InfoChip(
                      label: '已过期',
                      backgroundColor: AppColors.expiredChip,
                    ),
                  if (isRead)
                    const _InfoChip(
                      label: '已读',
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
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
