import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../providers/notice_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/notice_card.dart';

class NoticeListPage extends StatefulWidget {
  const NoticeListPage({super.key});

  @override
  State<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends State<NoticeListPage> {
  final RefreshController _refreshController = RefreshController();

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final noticeProvider = context.read<NoticeProvider>();
    final success = await noticeProvider.refreshNotices();
    if (!mounted) {
      return;
    }
    if (success) {
      _refreshController.refreshCompleted();
      _refreshController.resetNoData();
      _showMessage('通知已更新');
    } else {
      _refreshController.refreshFailed();
      _showMessage(noticeProvider.errorMessage ?? '刷新失败，请稍后再试');
    }
  }

  Future<void> _handleLoading() async {
    final noticeProvider = context.read<NoticeProvider>();
    final success = await noticeProvider.loadMore();
    if (!mounted) {
      return;
    }
    if (success) {
      if (noticeProvider.hasMore) {
        _refreshController.loadComplete();
      } else {
        _refreshController.loadNoData();
      }
    } else {
      _refreshController.loadFailed();
      _showMessage(noticeProvider.errorMessage ?? '加载更多失败');
    }
  }

  Future<void> _openDislikeDialog(String genre) async {
    final userProvider = context.read<UserProvider>();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '屏蔽此类通知？',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.small),
              Text('后续“$genre”类型通知将从首页隐藏，可在设置页恢复。'),
              const SizedBox(height: AppSpacing.large),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('确认屏蔽'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      await userProvider.addDislikedGenre(genre);
      if (!mounted) {
        return;
      }
      _showMessage('已屏蔽 $genre 通知');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NoticeProvider, UserProvider>(
      builder: (context, noticeProvider, userProvider, child) {
        final studentInfo = userProvider.studentInfo;
        final notices = noticeProvider.notices;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppConstants.appName),
            actions: [
              IconButton(
                tooltip: '个人信息',
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.userInfo);
                },
                icon: const Icon(Icons.badge_outlined),
              ),
              IconButton(
                tooltip: '设置',
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.setting);
                },
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          body: Column(
            children: [
              if (!(studentInfo?.isComplete ?? false))
                Material(
                  color: AppColors.warningBackground,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.userInfo);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.medium),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: AppSpacing.small),
                          Expanded(
                            child: Text(
                              '完善个人信息后，通知将按学院、书院、年级与专业进行个性化排序。',
                            ),
                          ),
                          Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              if (noticeProvider.errorMessage != null && notices.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                    vertical: AppSpacing.small,
                  ),
                  color: AppColors.infoBackground,
                  child: Text(
                    '提示：${noticeProvider.errorMessage}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (noticeProvider.isLoading && notices.isEmpty) {
                      return LoadingWidget(
                        message: '正在拉取校园通知...',
                        onRetry: () {
                          noticeProvider.refreshNotices(showLoading: true);
                        },
                      );
                    }

                    if (noticeProvider.errorMessage != null &&
                        notices.isEmpty) {
                      return LoadingWidget(
                        message: noticeProvider.errorMessage ?? '加载失败',
                        isError: true,
                        onRetry: () {
                          noticeProvider.refreshNotices(showLoading: true);
                        },
                      );
                    }

                    if (notices.isEmpty) {
                      return EmptyWidget(
                        message: userProvider.preference.dislikedGenres.isEmpty
                            ? '当前没有可展示的通知'
                            : '所有通知类型都被过滤了，去设置页恢复看看',
                      );
                    }

                    return SmartRefresher(
                      controller: _refreshController,
                      enablePullDown: true,
                      enablePullUp: noticeProvider.hasMore,
                      header: const WaterDropHeader(),
                      footer: const ClassicFooter(
                        loadStyle: LoadStyle.ShowWhenLoading,
                      ),
                      onRefresh: _handleRefresh,
                      onLoading: _handleLoading,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        itemCount: notices.length,
                          itemBuilder: (context, index) {
                            final itemContext = context;
                            final notice = notices[index];
                            final isRead = userProvider.preference.readNoticeIds
                                .contains(notice.id);
                            return NoticeCard(
                              notice: notice,
                              isRead: isRead,
                              onTap: () async {
                                await userProvider.markNoticeRead(notice.id);
                                if (!itemContext.mounted) {
                                  return;
                                }
                                Navigator.of(itemContext).pushNamed(
                                  AppRoutes.noticeDetail,
                                  arguments: notice,
                                );
                            },
                            onMarkDislike: () =>
                                _openDislikeDialog(notice.genre),
                          );
                        },
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.medium),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
