import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notice_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, NoticeProvider>(
      builder: (context, userProvider, noticeProvider, child) {
        final preference = userProvider.preference;
        return Scaffold(
          appBar: AppBar(
            title: const Text('设置'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.large),
            children: [
              Text(
                '通知类型权重',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.small),
              const Text('滑块范围为 -0.5 到 +0.5，调整后会实时影响个性化排序。'),
              const SizedBox(height: AppSpacing.medium),
              ...AppConstants.noticeGenres.map(
                (genre) {
                  final value = preference.customWeights[genre] ?? 0;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(genre)),
                              Text(value.toStringAsFixed(2)),
                            ],
                          ),
                          Slider(
                            value: value,
                            min: -0.5,
                            max: 0.5,
                            divisions: 10,
                            label: value.toStringAsFixed(1),
                            onChanged: (newValue) {
                              userProvider.updateCustomWeight(genre, newValue);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.large),
              Text(
                '已屏蔽类型',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.small),
              preference.dislikedGenres.isEmpty
                  ? const Text('当前没有屏蔽任何通知类型。')
                  : Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small,
                      children: preference.dislikedGenres.map((genre) {
                        return InputChip(
                          label: Text(genre),
                          onDeleted: () {
                            userProvider.removeDislikedGenre(genre);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text('已恢复 $genre 通知'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                          },
                        );
                      }).toList(),
                    ),
              const SizedBox(height: AppSpacing.large),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '数据管理',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          await noticeProvider.clearCache();
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text('本地通知缓存已清除'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        },
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: const Text('清除本地通知缓存'),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                        ),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('重置所有设置'),
                                content: const Text(
                                  '这会清空通知缓存、个人信息、已读状态和个性化偏好，确定继续吗？',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop(false);
                                    },
                                    child: const Text('取消'),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop(true);
                                    },
                                    child: const Text('确认重置'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirmed != true) {
                            return;
                          }
                          await userProvider.resetAll();
                          await noticeProvider.resetAllData();
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text('所有设置已重置'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('重置所有设置'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
