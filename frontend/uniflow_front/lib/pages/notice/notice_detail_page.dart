import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/notice_model.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';

class NoticeDetailPage extends StatelessWidget {
  const NoticeDetailPage({
    super.key,
    required this.notice,
  });

  final NoticeModel? notice;

  @override
  Widget build(BuildContext context) {
    final currentNotice = notice;
    if (currentNotice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('通知详情')),
        body: const Center(
          child: Text('通知参数缺失，暂时无法展示详情。'),
        ),
      );
    }

    final isExpired = AppDateUtils.isExpired(currentNotice);
    final publishedTime = AppDateUtils.extractPublishedTime(currentNotice);
    final sortedTimeline = AppDateUtils.sortTimeline(currentNotice.timeline);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知详情'),
        actions: [
          if (currentNotice.link.trim().isNotEmpty)
            IconButton(
              tooltip: '查看原文',
              onPressed: () => _openUrl(
                context: context,
                url: currentNotice.link,
                errorMessage: '原文链接打开失败',
              ),
              icon: const Icon(Icons.open_in_new),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentNotice.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small,
                      children: [
                        _buildTag(
                          context,
                          label: currentNotice.genre,
                          color: AppColors.genreChip,
                        ),
                        _buildTag(
                          context,
                          label: currentNotice.source,
                          color: AppColors.sourceChip,
                        ),
                        _buildTag(
                          context,
                          label: '重要度 ${currentNotice.importance}',
                          color: AppColors.importanceChip,
                        ),
                        _buildTag(
                          context,
                          label: isExpired ? '已过期' : '进行中',
                          color: isExpired
                              ? AppColors.expiredChip
                              : AppColors.activeChip,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Text('摘要：${currentNotice.review}'),
                    const SizedBox(height: AppSpacing.small),
                    Text('发布时间：${AppDateUtils.formatDateTime(publishedTime)}'),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      '抓取时间：${AppDateUtils.formatDateTime(AppDateUtils.parseDateTime(currentNotice.fetchTime))}',
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text('关键词：${currentNotice.keywords}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              '通知正文',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Html(
                  data: currentNotice.originalText.trim().isEmpty
                      ? '<p>暂无正文内容</p>'
                      : currentNotice.originalText,
                  onLinkTap: (url, _, __) {
                    _openUrl(
                      context: context,
                      url: url ?? '',
                      errorMessage: '正文链接打开失败',
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              '时间线',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  children: sortedTimeline.map((node) {
                    final entry = node.entries.first;
                    final nodeTime = AppDateUtils.parseDateTime(entry.value);
                    final isPast =
                        nodeTime != null && nodeTime.isBefore(DateTime.now());
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      decoration: BoxDecoration(
                        color: isPast
                            ? AppColors.timelinePast
                            : AppColors.timelineFuture,
                        borderRadius: BorderRadius.circular(AppRadii.medium),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.schedule,
                            color: isPast
                                ? AppColors.textSecondary
                                : AppColors.brandPrimary,
                          ),
                          const SizedBox(width: AppSpacing.small),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: isPast
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry.value,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: isPast
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              '附件列表',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: currentNotice.attachment.isEmpty
                    ? const Text('暂无附件')
                    : Column(
                        children: currentNotice.attachment.map((item) {
                          final entry = item.entries.first;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.attach_file),
                            title: Text(entry.key),
                            subtitle: Text(entry.value),
                            onTap: () => _openUrl(
                              context: context,
                              url: entry.value,
                              errorMessage: '附件链接打开失败',
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(
    BuildContext context, {
    required String label,
    required Color color,
  }) {
    return Chip(
      label: Text(label),
      backgroundColor: color,
      side: BorderSide.none,
      labelStyle: Theme.of(context).textTheme.labelMedium,
    );
  }

  Future<void> _openUrl({
    required BuildContext context,
    required String url,
    required String errorMessage,
  }) async {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      _showMessage(context, errorMessage);
      return;
    }
    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!success && context.mounted) {
        _showMessage(context, errorMessage);
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, errorMessage);
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
