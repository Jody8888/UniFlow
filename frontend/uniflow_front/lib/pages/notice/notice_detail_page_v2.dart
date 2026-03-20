import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/notice_model.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';

class NoticeDetailPage extends StatefulWidget {
  const NoticeDetailPage({
    super.key,
    required this.notice,
  });

  final NoticeModel? notice;

  @override
  State<NoticeDetailPage> createState() => _NoticeDetailPageState();
}

class _NoticeDetailPageState extends State<NoticeDetailPage> {
  Future<NoticeModel?>? _detailFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detailFuture ??= _loadNotice();
  }

  Future<NoticeModel?> _loadNotice() async {
    final currentNotice = widget.notice;
    if (currentNotice == null) {
      return null;
    }
    if (!_needsDetailFetch(currentNotice)) {
      return currentNotice;
    }

    final apiService = ApiService();
    apiService.updateSource(
      context.read<UserProvider>().preference.activeApiSource,
    );

    try {
      return await apiService.fetchNoticeDetail(currentNotice.id);
    } catch (_) {
      return currentNotice;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<NoticeModel?>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final currentNotice = snapshot.data;
        if (currentNotice == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.noticeDetail)),
            body: Center(child: Text(l10n.noticeDetailMissing)),
          );
        }

        final isExpired = AppDateUtils.isExpired(currentNotice);
        final publishedTime = AppDateUtils.extractPublishedTime(currentNotice);
        final sortedTimeline =
            AppDateUtils.sortTimeline(currentNotice.timeline);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.noticeDetail),
            actions: [
              if (currentNotice.link.trim().isNotEmpty)
                IconButton(
                  tooltip: l10n.viewOriginal,
                  onPressed: () => _openUrl(
                    context: context,
                    url: currentNotice.link,
                    errorMessage: l10n.openOriginalFailed,
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
                              label: l10n.importance(
                                '${currentNotice.importance}',
                              ),
                              color: AppColors.importanceChip,
                            ),
                            _buildTag(
                              context,
                              label: isExpired ? l10n.expired : l10n.ongoing,
                              color: isExpired
                                  ? AppColors.expiredChip
                                  : AppColors.activeChip,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        Text(l10n.summary(currentNotice.review)),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          l10n.publishedAt(
                            AppDateUtils.formatDateTime(publishedTime),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          l10n.fetchedAt(
                            AppDateUtils.formatDateTime(
                              AppDateUtils.parseDateTime(
                                currentNotice.fetchTime,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(l10n.keywords(currentNotice.keywords)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                Text(
                  l10n.noticeBody,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.small),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Html(
                      data: currentNotice.originalText.trim().isEmpty
                          ? l10n.emptyBodyHtml
                          : currentNotice.originalText,
                      onLinkTap: (url, _, __) {
                        _openUrl(
                          context: context,
                          url: url ?? '',
                          errorMessage: l10n.openBodyLinkFailed,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                Text(
                  l10n.timeline,
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
                        final isPast = nodeTime != null &&
                            nodeTime.isBefore(DateTime.now());
                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: AppSpacing.medium,
                          ),
                          padding: const EdgeInsets.all(AppSpacing.medium),
                          decoration: BoxDecoration(
                            color: isPast
                                ? AppColors.timelinePast
                                : AppColors.timelineFuture,
                            borderRadius: BorderRadius.circular(
                              AppRadii.medium,
                            ),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                  l10n.attachments,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.small),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: currentNotice.attachment.isEmpty
                        ? Text(l10n.noAttachments)
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
                                  errorMessage: l10n.openAttachmentFailed,
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
      },
    );
  }

  bool _needsDetailFetch(NoticeModel notice) {
    return notice.originalText.trim().isEmpty ||
        notice.link.trim().isEmpty ||
        notice.attachment.isEmpty ||
        _looksLikePublishOnlyTimeline(notice.timeline);
  }

  bool _looksLikePublishOnlyTimeline(List<Map<String, String>> timeline) {
    if (timeline.isEmpty) {
      return true;
    }
    if (timeline.length > 1) {
      return false;
    }
    final firstKey = timeline.first.entries.first.key;
    return firstKey.contains('发布');
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
