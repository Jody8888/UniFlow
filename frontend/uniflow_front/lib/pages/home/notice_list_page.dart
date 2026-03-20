import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../l10n/app_localizations.dart';
import '../../models/notice_model.dart';
import '../../models/student_info.dart';
import '../../providers/notice_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/calendar_service.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/notice_card.dart';
import '../../widgets/timeline_calendar.dart';

class NoticeListPage extends StatefulWidget {
  const NoticeListPage({super.key});

  @override
  State<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends State<NoticeListPage>
    with SingleTickerProviderStateMixin {
  final RefreshController _refreshController = RefreshController();
  final CalendarService _calendarService = CalendarService();
  late final TabController _tabController;
  String? _selectedTimelineRange;
  final Set<String> _selectedNoticeIds = <String>{};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final l10n = context.l10n;
    final noticeProvider = context.read<NoticeProvider>();
    final success = await noticeProvider.refreshNotices();
    if (!mounted) {
      return;
    }
    if (success) {
      _refreshController.refreshCompleted();
      _refreshController.resetNoData();
      _showMessage(l10n.updatedNotices);
    } else {
      _refreshController.refreshFailed();
      _showMessage(noticeProvider.errorMessage ?? l10n.refreshFailed);
    }
  }

  Future<void> _handleLoading() async {
    final l10n = context.l10n;
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
      _showMessage(noticeProvider.errorMessage ?? l10n.loadMoreFailed);
    }
  }

  Future<void> _openDislikeDialog(String genre) async {
    final l10n = context.l10n;
    final userProvider = context.read<UserProvider>();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.dislikeNoticeTitle, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.small),
              Text(l10n.dislikeNoticeContent(genre)),
              const SizedBox(height: AppSpacing.large),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      child: Text(l10n.confirmBlock),
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
      _showMessage(l10n.genreBlocked(genre));
    }
  }

  Future<void> _updateSortMode(String mode) async {
    final l10n = context.l10n;
    await context.read<UserProvider>().updateHomeSortMode(mode);
    if (!mounted) {
      return;
    }
    _showMessage(l10n.switchedSort(l10n.sortModeLabel(mode)));
  }

  Future<void> _openNoticeDetail(NoticeModel notice) async {
    final userProvider = context.read<UserProvider>();
    await userProvider.markNoticeRead(notice.id);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushNamed(AppRoutes.noticeDetail, arguments: notice);
  }

  Future<void> _toggleFavorite(NoticeModel notice) async {
    await context.read<UserProvider>().toggleFavoriteNotice(notice.id);
    if (!mounted) {
      return;
    }
    _showMessage(context.l10n.favoriteUpdated(notice.title));
  }

  void _toggleSelection(String noticeId) {
    setState(() {
      if (_selectedNoticeIds.contains(noticeId)) {
        _selectedNoticeIds.remove(noticeId);
      } else {
        _selectedNoticeIds.add(noticeId);
      }
    });
  }

  void _enterSelection(String noticeId) {
    setState(() {
      _selectionMode = true;
      _selectedNoticeIds.add(noticeId);
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedNoticeIds.clear();
    });
  }

  Future<void> _applyBatchFavorite(bool favorite) async {
    if (_selectedNoticeIds.isEmpty) {
      return;
    }
    await context.read<UserProvider>().setFavoriteStateForBatch(
          _selectedNoticeIds,
          favorite: favorite,
        );
    if (!mounted) {
      return;
    }
    _showMessage(
      favorite ? context.l10n.batchFavorite : context.l10n.batchUnfavorite,
    );
    _exitSelection();
  }

  Future<void> _exportFavorites(List<NoticeModel> favorites) async {
    if (favorites.isEmpty) {
      _showMessage(context.l10n.favoriteEmpty);
      return;
    }
    try {
      final path = await _calendarService.exportNoticesAsIcs(favorites);
      await _calendarService.shareIcsFile(path);
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.exportIcsDone);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.exportIcsFailed);
    }
  }

  Future<void> _previewAndImportFavorites(List<NoticeModel> favorites) async {
    if (favorites.isEmpty) {
      _showMessage(context.l10n.favoriteEmpty);
      return;
    }
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.calendarPreviewTitle),
          content: SingleChildScrollView(
            child: SelectableText(_calendarService.previewEvent(favorites.first)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.importCalendar),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _calendarService.importToSystemCalendar(favorites);
      if (!mounted) {
        return;
      }
      _showMessage(l10n.calendarImportDone);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.calendarImportFailed);
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
        final l10n = context.l10n;
        final studentInfo = userProvider.studentInfo;
        final notices = noticeProvider.notices;
        final currentSortMode = userProvider.preference.homeSortMode;
        final timelineRange = _selectedTimelineRange ?? userProvider.preference.timelineRange;
        final favoriteIds = userProvider.preference.favoriteNoticeIds;
        final favoriteNotices = notices
            .where((notice) => favoriteIds.contains(notice.id))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.appName),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.noticeView, icon: const Icon(Icons.view_list_outlined)),
                Tab(text: l10n.favoritesView, icon: const Icon(Icons.star_outline)),
                Tab(text: l10n.timelineView, icon: const Icon(Icons.calendar_month_outlined)),
              ],
            ),
            actions: [
              if (_selectionMode)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.small),
                    child: Text(l10n.selectedCount('${_selectedNoticeIds.length}')),
                  ),
                ),
              if (_selectionMode)
                IconButton(
                  tooltip: l10n.batchFavorite,
                  onPressed: () => _applyBatchFavorite(true),
                  icon: const Icon(Icons.star),
                ),
              if (_selectionMode)
                IconButton(
                  tooltip: l10n.batchUnfavorite,
                  onPressed: () => _applyBatchFavorite(false),
                  icon: const Icon(Icons.star_border),
                ),
              if (_selectionMode)
                IconButton(
                  tooltip: l10n.exitSelection,
                  onPressed: _exitSelection,
                  icon: const Icon(Icons.close),
                ),
              if (!_selectionMode && _tabController.index == 1)
                IconButton(
                  tooltip: l10n.exportIcs,
                  onPressed: () => _exportFavorites(favoriteNotices),
                  icon: const Icon(Icons.ios_share_outlined),
                ),
              if (!_selectionMode && _tabController.index == 1)
                IconButton(
                  tooltip: l10n.importCalendar,
                  onPressed: () => _previewAndImportFavorites(favoriteNotices),
                  icon: const Icon(Icons.event_available_outlined),
                ),
              PopupMenuButton<String>(
                tooltip: l10n.sortMode,
                onSelected: _updateSortMode,
                itemBuilder: (_) {
                  return AppSortModes.values.map((mode) {
                    return PopupMenuItem<String>(
                      value: mode,
                      child: Row(
                        children: [
                          Icon(currentSortMode == mode ? Icons.radio_button_checked : Icons.radio_button_off, size: 18),
                          const SizedBox(width: AppSpacing.small),
                          Text(l10n.sortModeLabel(mode)),
                        ],
                      ),
                    );
                  }).toList();
                },
                icon: const Icon(Icons.sort),
              ),
              IconButton(
                tooltip: l10n.personalInfo,
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.userInfo),
                icon: const Icon(Icons.badge_outlined),
              ),
              IconButton(
                tooltip: l10n.settings,
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.setting),
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildNoticeTab(context, noticeProvider, userProvider, studentInfo, notices, currentSortMode),
              _buildFavoritesTab(context, userProvider, favoriteNotices),
              TimelineCalendar(
                notices: notices,
                selectedRange: timelineRange,
                onRangeChanged: (value) {
                  setState(() {
                    _selectedTimelineRange = value;
                  });
                },
                onNoticeTap: _openNoticeDetail,
                favoriteIds: favoriteIds,
                onToggleFavorite: _toggleFavorite,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoticeTab(
    BuildContext context,
    NoticeProvider noticeProvider,
    UserProvider userProvider,
    StudentInfo? studentInfo,
    List<NoticeModel> notices,
    String currentSortMode,
  ) {
    final l10n = context.l10n;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(AppSpacing.medium, 0, AppSpacing.medium, AppSpacing.small),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(l10n.currentSortMode(l10n.sortModeLabel(currentSortMode))),
              side: BorderSide.none,
            ),
          ),
        ),
        if (!(studentInfo?.isComplete ?? false))
          Material(
            color: AppColors.warningBackground,
            child: InkWell(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.userInfo),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.medium),
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: AppSpacing.small),
                    Expanded(child: _PersonalHintText()),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
        if (noticeProvider.errorMessage != null && notices.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
            color: AppColors.infoBackground,
            child: Text(l10n.message(noticeProvider.errorMessage ?? ''), style: Theme.of(context).textTheme.bodySmall),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Builder(
              key: ValueKey<String>('${noticeProvider.isLoading}-${noticeProvider.errorMessage}-${notices.length}-$currentSortMode'),
              builder: (listContext) {
                if (noticeProvider.isLoading && notices.isEmpty) {
                  return LoadingWidget(
                    message: l10n.loadingNotices,
                    onRetry: () => noticeProvider.refreshNotices(showLoading: true),
                  );
                }
                if (noticeProvider.errorMessage != null && notices.isEmpty) {
                  return LoadingWidget(
                    message: noticeProvider.errorMessage ?? l10n.loadFailed,
                    isError: true,
                    onRetry: () => noticeProvider.refreshNotices(showLoading: true),
                  );
                }
                if (notices.isEmpty) {
                  return EmptyWidget(
                    message: userProvider.preference.dislikedGenres.isEmpty ? l10n.noNotice : l10n.allFiltered,
                  );
                }
                return SmartRefresher(
                  controller: _refreshController,
                  enablePullDown: true,
                  enablePullUp: noticeProvider.hasMore,
                  header: const WaterDropHeader(),
                  footer: const ClassicFooter(loadStyle: LoadStyle.ShowWhenLoading),
                  onRefresh: _handleRefresh,
                  onLoading: _handleLoading,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    itemCount: notices.length,
                    itemBuilder: (context, index) {
                      final notice = notices[index];
                      final isRead = userProvider.preference.readNoticeIds.contains(notice.id);
                      final isFavorite = userProvider.preference.favoriteNoticeIds.contains(notice.id);
                      return NoticeCard(
                        key: ValueKey<String>('${notice.id}-$isRead'),
                        notice: notice,
                        isRead: isRead,
                        isFavorite: isFavorite,
                        onTap: () => _openNoticeDetail(notice),
                        onMarkDislike: () => _openDislikeDialog(notice.genre),
                        onToggleFavorite: () => _toggleFavorite(notice),
                        selectionMode: _selectionMode,
                        selected: _selectedNoticeIds.contains(notice.id),
                        onSelectionToggle: () => _selectionMode
                            ? _toggleSelection(notice.id)
                            : _enterSelection(notice.id),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.medium),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab(
    BuildContext context,
    UserProvider userProvider,
    List<NoticeModel> favorites,
  ) {
    if (favorites.isEmpty) {
      return EmptyWidget(message: context.l10n.favoriteEmpty);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.medium),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final notice = favorites[index];
        return NoticeCard(
          key: ValueKey<String>('favorite-${notice.id}'),
          notice: notice,
          isRead: userProvider.preference.readNoticeIds.contains(notice.id),
          isFavorite: true,
          onTap: () => _openNoticeDetail(notice),
          onMarkDislike: () => _openDislikeDialog(notice.genre),
          onToggleFavorite: () => _toggleFavorite(notice),
          selectionMode: _selectionMode,
          selected: _selectedNoticeIds.contains(notice.id),
          onSelectionToggle: () => _selectionMode
              ? _toggleSelection(notice.id)
              : _enterSelection(notice.id),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.medium),
    );
  }
}

class _PersonalHintText extends StatelessWidget {
  const _PersonalHintText();

  @override
  Widget build(BuildContext context) {
    return Text(context.l10n.personalInfoHint);
  }
}
