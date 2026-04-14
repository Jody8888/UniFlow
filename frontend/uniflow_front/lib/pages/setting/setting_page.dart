import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/api_source_config.dart';
import '../../providers/notice_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/desktop_widget_preview.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  int _selectedSectionIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, NoticeProvider>(
      builder: (context, userProvider, noticeProvider, child) {
        final sections = _buildSections(context, userProvider, noticeProvider);
        final layout = userProvider.preference.settingsLayout;
        if (_selectedSectionIndex >= sections.length) {
          _selectedSectionIndex = 0;
        }

        switch (layout) {
          case AppSettingsLayouts.verticalTabs:
            return _buildVerticalLayout(context, sections);
          case AppSettingsLayouts.secondaryMenu:
            return _buildSecondaryMenuLayout(context, sections);
          case AppSettingsLayouts.horizontalTabs:
          default:
            return _buildHorizontalLayout(context, sections);
        }
      },
    );
  }

  List<_SettingSectionData> _buildSections(
    BuildContext context,
    UserProvider userProvider,
    NoticeProvider noticeProvider,
  ) {
    final l10n = context.l10n;
    return <_SettingSectionData>[
      _SettingSectionData(
        title: l10n.update,
        icon: Icons.update_outlined,
        builder: () =>
            _buildUpdateSection(context, userProvider, noticeProvider),
      ),
      _SettingSectionData(
        title: l10n.dataSources,
        icon: Icons.cloud_outlined,
        builder: () => _buildApiSourceSection(context, userProvider),
      ),
      _SettingSectionData(
        title: l10n.weights,
        icon: Icons.tune_outlined,
        builder: () => _buildWeightSection(context, userProvider),
      ),
      _SettingSectionData(
        title: l10n.general,
        icon: Icons.settings_outlined,
        builder: () =>
            _buildGeneralSection(context, userProvider, noticeProvider),
      ),
      _SettingSectionData(
        title: l10n.widgetSettings,
        icon: Icons.widgets_outlined,
        builder: () =>
            _buildWidgetSection(context, userProvider, noticeProvider),
      ),
      _SettingSectionData(
        title: l10n.about,
        icon: Icons.info_outline,
        builder: () => _buildAboutSection(context),
      ),
    ];
  }

  Widget _buildHorizontalLayout(
    BuildContext context,
    List<_SettingSectionData> sections,
  ) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: sections.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settings),
          bottom: TabBar(
            isScrollable: true,
            tabs: sections
                .map(
                  (section) => Tab(
                    text: section.title,
                    icon: Icon(section.icon),
                  ),
                )
                .toList(),
          ),
        ),
        body: TabBarView(
          children: sections.map((section) => section.builder()).toList(),
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(
    BuildContext context,
    List<_SettingSectionData> sections,
  ) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedSectionIndex,
            extended: MediaQuery.of(context).size.width >= 960,
            onDestinationSelected: (index) {
              setState(() {
                _selectedSectionIndex = index;
              });
            },
            destinations: sections
                .map(
                  (section) => NavigationRailDestination(
                    icon: Icon(section.icon),
                    label: Text(section.title),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedSectionIndex),
                child: sections[_selectedSectionIndex].builder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryMenuLayout(
    BuildContext context,
    List<_SettingSectionData> sections,
  ) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.large),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Card(
            child: ListTile(
              leading: Icon(section.icon),
              title: Text(section.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _SettingSectionPage(
                      title: section.title,
                      child: section.builder(),
                    ),
                  ),
                );
              },
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.small),
        itemCount: sections.length,
      ),
    );
  }

  Widget _buildUpdateSection(
    BuildContext context,
    UserProvider userProvider,
    NoticeProvider noticeProvider,
  ) {
    final l10n = context.l10n;
    final preference = userProvider.preference;
    final messenger = ScaffoldMessenger.of(context);
    final refreshValueController = TextEditingController(
      text: '${preference.autoRefreshValue}',
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Text(l10n.updateFrequency,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        Text(l10n.updateFrequencyDesc),
        const SizedBox(height: AppSpacing.medium),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: refreshValueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.autoRefreshValue),
                onSubmitted: (raw) async {
                  final parsed = int.tryParse(raw.trim());
                  if (parsed == null) {
                    return;
                  }
                  await userProvider.updateAutoRefresh(
                    value: parsed,
                    unit: preference.autoRefreshUnit,
                  );
                  if (!mounted) {
                    return;
                  }
                  _showMessage(
                    messenger,
                    parsed == 0
                        ? l10n.disabledAutoUpdate
                        : l10n.updatedAutoUpdate,
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: preference.autoRefreshUnit,
                decoration: InputDecoration(labelText: l10n.autoRefreshUnit),
                items: AppRefreshUnits.values.map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(l10n.refreshUnitLabel(value)),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value == null) {
                    return;
                  }
                  final parsed = int.tryParse(refreshValueController.text.trim()) ??
                      preference.autoRefreshValue;
                  await userProvider.updateAutoRefresh(
                    value: parsed,
                    unit: value,
                  );
                  if (!mounted) {
                    return;
                  }
                  _showMessage(
                    messenger,
                    parsed == 0
                        ? l10n.disabledAutoUpdate
                        : l10n.updatedAutoUpdate,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        Text(l10n.autoRefreshHint),
        const SizedBox(height: AppSpacing.large),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.currentDataSource,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.small),
                Text(preference.activeApiSource.name),
                const SizedBox(height: 4),
                Text(preference.activeApiSource.displayUrl,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.medium),
                FilledButton.icon(
                  onPressed: () async {
                    final success =
                        await noticeProvider.refreshNotices(showLoading: true);
                    if (!mounted) {
                      return;
                    }
                    _showMessage(
                        messenger,
                        success
                            ? l10n.manualRefreshDone
                            : noticeProvider.errorMessage ??
                                l10n.manualRefreshFailed);
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.refreshNow),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiSourceSection(
      BuildContext context, UserProvider userProvider) {
    final l10n = context.l10n;
    final preference = userProvider.preference;
    final messenger = ScaffoldMessenger.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Row(
          children: [
            Expanded(
                child: Text(l10n.dataSources,
                    style: Theme.of(context).textTheme.titleLarge)),
            FilledButton.icon(
              onPressed: () => _createOrEditSource(context, userProvider),
              icon: const Icon(Icons.add),
              label: Text(l10n.add),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        Text(l10n.apiSourcesDesc),
        const SizedBox(height: AppSpacing.medium),
        ...preference.apiSources.map((source) {
          final selected = source.id == preference.activeApiSourceId;
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.large),
              onTap: () async {
                await userProvider.setActiveApiSource(source.id);
                if (!mounted) {
                  return;
                }
                _showMessage(
                    messenger, l10n.switchedApiSourceMessage(source.name));
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(source.name,
                                style:
                                    Theme.of(context).textTheme.titleMedium)),
                        if (selected)
                          Chip(
                              label: Text(l10n.currentSource),
                              side: BorderSide.none),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(source.displayUrl),
                    const SizedBox(height: AppSpacing.medium),
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small,
                      children: [
                        OutlinedButton(
                          onPressed: () => _createOrEditSource(
                              context, userProvider,
                              source: source),
                          child: Text(l10n.edit),
                        ),
                        OutlinedButton(
                          onPressed: source.id == 'mock-default'
                              ? null
                              : () async {
                                  await userProvider.removeApiSource(source.id);
                                  if (!mounted) {
                                    return;
                                  }
                                  _showMessage(
                                      messenger,
                                      l10n.removedApiSourceMessage(
                                          source.name));
                                },
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWeightSection(BuildContext context, UserProvider userProvider) {
    final l10n = context.l10n;
    final preference = userProvider.preference;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Text(l10n.manualWeightSettings,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        Text(l10n.manualWeightDesc),
        const SizedBox(height: AppSpacing.medium),
        ...AppConstants.noticeGenres.map((genre) {
          final value = preference.customWeights[genre] ?? 0;
          return Card(
            child: ListTile(
              title: Text(genre),
              subtitle: Text('${l10n.weights}: ${value.toStringAsFixed(2)}'),
              trailing: FilledButton.tonal(
                onPressed: () =>
                    _editWeight(context, userProvider, genre, value),
                child: Text(l10n.manualInput),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGeneralSection(BuildContext context, UserProvider userProvider,
      NoticeProvider noticeProvider) {
    final l10n = context.l10n;
    final preference = userProvider.preference;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Text(l10n.homeSortStandard,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        DropdownButtonFormField<String>(
          initialValue: preference.homeSortMode,
          decoration: InputDecoration(labelText: l10n.defaultSortMode),
          items: AppSortModes.values.map((mode) {
            return DropdownMenuItem<String>(
                value: mode, child: Text(l10n.sortModeLabel(mode)));
          }).toList(),
          onChanged: (value) async {
            if (value == null) {
              return;
            }
            await userProvider.updateHomeSortMode(value);
            if (!mounted) {
              return;
            }
            _showMessage(messenger, l10n.updatedSortMode);
          },
        ),
        const SizedBox(height: AppSpacing.large),
        Text(l10n.appearanceSettings,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        DropdownButtonFormField<String>(
          initialValue: preference.themeMode,
          decoration: InputDecoration(labelText: l10n.themeMode),
          items: AppThemeModes.values.map((value) {
            return DropdownMenuItem<String>(
                value: value, child: Text(l10n.themeModeLabel(value)));
          }).toList(),
          onChanged: (value) async {
            if (value == null) {
              return;
            }
            await userProvider.updateThemeMode(value);
            if (!mounted) {
              return;
            }
            _showMessage(messenger, l10n.themeModeSaved);
          },
        ),
        const SizedBox(height: AppSpacing.medium),
        DropdownButtonFormField<String>(
          initialValue: preference.themePreset,
          decoration: InputDecoration(labelText: l10n.themePreset),
          items: AppThemePresets.values.map((value) {
            final seedColor = AppThemePresets.seedColorOf(value);
            final backgroundColor = AppThemePresets.backgroundColorOf(value);
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                          color: seedColor, shape: BoxShape.circle)),
                  const SizedBox(width: AppSpacing.small),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Text(l10n.themePresetLabel(value)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) async {
            if (value == null) {
              return;
            }
            await userProvider.updateThemePreset(value);
            if (!mounted) {
              return;
            }
            _showMessage(messenger, l10n.themePresetSaved);
          },
        ),
        const SizedBox(height: AppSpacing.medium),
        Card(
          child: ListTile(
            title: Text(l10n.themeAccentColor),
            subtitle: Text(
              preference.customThemeColorHex ??
                  AppThemePresets.toHex(
                    AppThemePresets.seedColorOf(preference.themePreset),
                  ),
            ),
            leading: _ColorPreview(
              color: AppThemePresets.parseHexColor(
                    preference.customThemeColorHex,
                  ) ??
                  AppThemePresets.seedColorOf(preference.themePreset),
            ),
            trailing: FilledButton.tonal(
              onPressed: () => _editThemeColor(
                context,
                userProvider,
                colorRole: _ThemeColorRole.seed,
              ),
              child: Text(l10n.choose),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Card(
          child: ListTile(
            title: Text(l10n.themeForegroundColor),
            subtitle: Text(
              preference.customForegroundColorHex ??
                  AppThemePresets.toHex(
                    AppThemePresets.foregroundColorOf(preference.themePreset),
                  ),
            ),
            leading: _ColorPreview(
              color: AppThemePresets.parseHexColor(
                    preference.customForegroundColorHex,
                  ) ??
                  AppThemePresets.foregroundColorOf(preference.themePreset),
            ),
            trailing: FilledButton.tonal(
              onPressed: () => _editThemeColor(
                context,
                userProvider,
                colorRole: _ThemeColorRole.foreground,
              ),
              child: Text(l10n.choose),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Card(
          child: ListTile(
            title: Text(l10n.themeBackgroundColor),
            subtitle: Text(
              preference.customBackgroundColorHex ??
                  AppThemePresets.toHex(
                    AppThemePresets.backgroundColorOf(preference.themePreset),
                  ),
            ),
            leading: _ColorPreview(
              color: AppThemePresets.parseHexColor(
                    preference.customBackgroundColorHex,
                  ) ??
                  AppThemePresets.backgroundColorOf(preference.themePreset),
            ),
            trailing: FilledButton.tonal(
              onPressed: () => _editThemeColor(
                context,
                userProvider,
                colorRole: _ThemeColorRole.background,
              ),
              child: Text(l10n.choose),
            ),
          ),
        ),
        if (preference.customThemeColorHex != null ||
            preference.customForegroundColorHex != null ||
            preference.customBackgroundColorHex != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.small),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await userProvider.updateCustomThemeColor(null);
                  await userProvider.updateCustomForegroundColor(null);
                  await userProvider.updateCustomBackgroundColor(null);
                  if (!mounted) {
                    return;
                  }
                  _showMessage(messenger, l10n.clearCustomThemeColor);
                },
                child: Text(l10n.clearCustomThemeColor),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.large),
        Text(l10n.timelinePeriod,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        DropdownButtonFormField<String>(
          initialValue: preference.timelineRange,
          decoration: InputDecoration(labelText: l10n.timelineRange),
          items: AppTimelineRanges.values.map((value) {
            return DropdownMenuItem<String>(
                value: value, child: Text(l10n.timelineRangeLabel(value)));
          }).toList(),
          onChanged: (value) async {
            if (value == null) {
              return;
            }
            await userProvider.updateTimelineRange(value);
            if (!mounted) {
              return;
            }
            _showMessage(messenger, l10n.timelineRangeSaved);
          },
        ),
        const SizedBox(height: AppSpacing.large),
        Text(l10n.settingsDisplayMode,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        DropdownButtonFormField<String>(
          initialValue: preference.settingsLayout,
          decoration: InputDecoration(labelText: l10n.settingsDisplayMode),
          items: AppSettingsLayouts.values.map((value) {
            return DropdownMenuItem<String>(
                value: value, child: Text(l10n.settingsLayoutLabel(value)));
          }).toList(),
          onChanged: (value) async {
            if (value == null) {
              return;
            }
            await userProvider.updateSettingsLayout(value);
            if (!mounted) {
              return;
            }
            _showMessage(messenger, l10n.settingsDisplayModeSaved);
          },
        ),
        const SizedBox(height: AppSpacing.large),
        Text(l10n.languageSettings,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        DropdownButtonFormField<String>(
          initialValue: preference.languageCode,
          decoration: InputDecoration(labelText: l10n.appLanguage),
          items: AppLanguageOptions.values.map((value) {
            return DropdownMenuItem<String>(
                value: value, child: Text(l10n.languageLabel(value)));
          }).toList(),
          onChanged: (value) async {
            if (value == null) {
              return;
            }
            await userProvider.updateLanguageCode(value);
            if (!mounted) {
              return;
            }
            _showMessage(messenger, l10n.languageSaved);
          },
        ),
        const SizedBox(height: AppSpacing.large),
        Text(l10n.blockedTypes, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        preference.dislikedGenres.isEmpty
            ? Text(l10n.noBlockedTypes)
            : Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: preference.dislikedGenres.map((genre) {
                  return InputChip(
                    label: Text(genre),
                    onDeleted: () async {
                      await userProvider.removeDislikedGenre(genre);
                      if (!mounted) {
                        return;
                      }
                      _showMessage(messenger, l10n.restoredGenre(genre));
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
                Text(l10n.dataManagement,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.medium),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await noticeProvider.clearCache();
                    if (!mounted) {
                      return;
                    }
                    _showMessage(messenger, l10n.cacheCleared);
                  },
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: Text(l10n.clearCache),
                ),
                const SizedBox(height: AppSpacing.medium),
                FilledButton.icon(
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.danger),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: Text(l10n.resetAllSettings),
                          content: Text(l10n.resetAllSettingsConfirm),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: Text(l10n.cancel),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: Text(l10n.resetAllSettings),
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
                    if (!mounted) {
                      return;
                    }
                    _showMessage(messenger, l10n.allSettingsReset);
                    navigator.pop();
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: Text(l10n.resetAllSettings),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWidgetSection(
    BuildContext context,
    UserProvider userProvider,
    NoticeProvider noticeProvider,
  ) {
    final l10n = context.l10n;
    final preference = userProvider.preference;
    final messenger = ScaffoldMessenger.of(context);
    final previewNotices = noticeProvider.notices.take(4).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Text(
          l10n.widgetSettings,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.small),
        Text(l10n.widgetSectionDesc),
        const SizedBox(height: AppSpacing.large),
        DropdownButtonFormField<String>(
          initialValue: preference.widgetListSize,
          decoration: InputDecoration(labelText: l10n.listWidgetSize),
          items: AppWidgetSizes.values.map((value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(l10n.widgetSizeLabel(value)),
            );
          }).toList(),
          onChanged: (value) async {
            if (value == null) {
              return;
            }
            await userProvider.updateWidgetListSize(value);
            if (!mounted) {
              return;
            }
            _showMessage(messenger, l10n.widgetConfigSaved);
          },
        ),
        const SizedBox(height: AppSpacing.medium),
        DropdownButtonFormField<String>(
          initialValue: preference.widgetTimelineSize,
          decoration: InputDecoration(labelText: l10n.timelineWidgetSize),
          items: AppWidgetSizes.values.map((value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(l10n.widgetSizeLabel(value)),
            );
          }).toList(),
          onChanged: (value) async {
            if (value == null) {
              return;
            }
            await userProvider.updateWidgetTimelineSize(value);
            if (!mounted) {
              return;
            }
            _showMessage(messenger, l10n.widgetConfigSaved);
          },
        ),
        const SizedBox(height: AppSpacing.large),
        Text(
          l10n.widgetPreview,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.small),
        if (previewNotices.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Text(l10n.widgetEmptyHint),
            ),
          )
        else ...[
          DesktopWidgetPreview(
            title: l10n.widgetListMode,
            mode: 'list',
            size: preference.widgetListSize,
            notices: previewNotices,
          ),
          const SizedBox(height: AppSpacing.medium),
          DesktopWidgetPreview(
            title: l10n.widgetTimelineMode,
            mode: 'timeline',
            size: preference.widgetTimelineSize,
            notices: previewNotices,
          ),
        ],
        const SizedBox(height: AppSpacing.large),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Text(l10n.widgetAddHint),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DeveloperInfo.teamName,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.small),
                Text(DeveloperInfo.description),
                const SizedBox(height: AppSpacing.medium),
                Text(l10n.version(DeveloperInfo.version)),
                const SizedBox(height: 4),
                Text(l10n.maintainer(DeveloperInfo.maintainer)),
                const SizedBox(height: 4),
                Text(l10n.contact(DeveloperSupportLinks.contact)),
                const SizedBox(height: AppSpacing.large),
                Text(l10n.supportProject,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.small),
                Text(l10n.supportProjectDesc),
                const SizedBox(height: AppSpacing.medium),
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _openSupportLink(
                          context, DeveloperInfo.buyMeACoffeeUrl),
                      icon: const Icon(Icons.local_cafe_outlined),
                      label: Text(l10n.buyMeCoffee),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _openSupportLink(context, DeveloperInfo.afdianUrl),
                      icon: const Icon(Icons.favorite_border),
                      label: Text(l10n.afdian),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openSupportLink(
                        context,
                        DeveloperSupportLinks.patreonUrl,
                      ),
                      icon: const Icon(Icons.favorite_outline),
                      label: Text(l10n.patreon),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createOrEditSource(
      BuildContext context, UserProvider userProvider,
      {ApiSourceConfig? source}) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController(text: source?.name ?? '');
    final baseUrlController =
        TextEditingController(text: source?.baseUrl ?? '');
    final pathController = TextEditingController(
        text: source?.noticePath ?? AppConstants.noticePath);
    final apiKeyController = TextEditingController(text: source?.apiKey ?? '');
    var useMockData = source?.useMockData ?? false;

    final result = await showDialog<ApiSourceConfig>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogStateContext, setState) {
            return AlertDialog(
              title:
                  Text(source == null ? l10n.addApiSource : l10n.editApiSource),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: l10n.name)),
                    const SizedBox(height: AppSpacing.medium),
                    TextField(
                        controller: baseUrlController,
                        decoration: InputDecoration(labelText: l10n.baseUrl)),
                    const SizedBox(height: AppSpacing.medium),
                    TextField(
                        controller: pathController,
                        decoration:
                            InputDecoration(labelText: l10n.noticePath)),
                    const SizedBox(height: AppSpacing.medium),
                    TextField(
                      controller: apiKeyController,
                      decoration: InputDecoration(
                        labelText: l10n.apiKey,
                        hintText: l10n.apiKeyHint,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: useMockData,
                      title: Text(l10n.useMockData),
                      onChanged: (value) {
                        setState(() {
                          useMockData = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.cancel)),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final baseUrl = baseUrlController.text.trim();
                    final noticePath = pathController.text.trim().isEmpty
                        ? AppConstants.noticePath
                        : pathController.text.trim();
                    final next = ApiSourceConfig(
                      id: source?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name.isEmpty ? l10n.unnamedSource : name,
                      baseUrl: baseUrl,
                      noticePath: noticePath,
                      useMockData: useMockData,
                      apiKey: apiKeyController.text.trim(),
                    );
                    Navigator.of(dialogContext).pop(next);
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    if (source == null) {
      await userProvider.addApiSource(result);
      if (!mounted) {
        return;
      }
      _showMessage(messenger, l10n.addedApiSourceMessage(result.name));
    } else {
      await userProvider.updateApiSource(result);
      if (!mounted) {
        return;
      }
      _showMessage(messenger, l10n.updatedApiSourceMessage(result.name));
    }
  }

  Future<void> _editWeight(BuildContext context, UserProvider userProvider,
      String genre, double currentValue) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final controller =
        TextEditingController(text: currentValue.toStringAsFixed(2));
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.setGenreWeight(genre)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            decoration: InputDecoration(labelText: l10n.weightHint),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text.trim());
                Navigator.of(dialogContext).pop(value);
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (result == null) {
      return;
    }

    await userProvider.updateCustomWeight(genre, result);
    if (!mounted) {
      return;
    }
    _showMessage(messenger, l10n.updatedGenreWeight(genre));
  }

  Future<void> _editThemeColor(
    BuildContext context,
    UserProvider userProvider, {
    required _ThemeColorRole colorRole,
  }) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final preference = userProvider.preference;
    final Color initialColor;
    switch (colorRole) {
      case _ThemeColorRole.foreground:
        initialColor = AppThemePresets.parseHexColor(
              preference.customForegroundColorHex,
            ) ??
            AppThemePresets.foregroundColorOf(preference.themePreset);
        break;
      case _ThemeColorRole.background:
        initialColor = AppThemePresets.parseHexColor(
              preference.customBackgroundColorHex,
            ) ??
            AppThemePresets.backgroundColorOf(preference.themePreset);
        break;
      case _ThemeColorRole.seed:
        initialColor = AppThemePresets.parseHexColor(
              preference.customThemeColorHex,
            ) ??
            AppThemePresets.seedColorOf(preference.themePreset);
        break;
    }
    final result = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return _ThemeColorDialog(
          title: switch (colorRole) {
            _ThemeColorRole.seed => l10n.themeAccentColor,
            _ThemeColorRole.foreground => l10n.themeForegroundColor,
            _ThemeColorRole.background => l10n.themeBackgroundColor,
          },
          initialColor: initialColor,
        );
      },
    );

    if (result == null) {
      return;
    }

    final hex = AppThemePresets.toHex(result);
    switch (colorRole) {
      case _ThemeColorRole.seed:
        await userProvider.updateCustomThemeColor(hex);
        break;
      case _ThemeColorRole.foreground:
        await userProvider.updateCustomForegroundColor(hex);
        break;
      case _ThemeColorRole.background:
        await userProvider.updateCustomBackgroundColor(hex);
        break;
    }
    if (!mounted) {
      return;
    }
    _showMessage(messenger, l10n.customThemeColorSaved);
  }

  Future<void> _openSupportLink(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showMessage(messenger, l10n.openSupportLinkFailed);
      return;
    }
    try {
      final success =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!success && mounted) {
        _showMessage(messenger, l10n.openSupportLinkFailed);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(messenger, l10n.openSupportLinkFailed);
      }
    }
  }

  void _showMessage(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _SettingSectionData {
  const _SettingSectionData(
      {required this.title, required this.icon, required this.builder});

  final String title;
  final IconData icon;
  final Widget Function() builder;
}

enum _ThemeColorRole { seed, foreground, background }

class _ColorPreview extends StatelessWidget {
  const _ColorPreview({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}

class _ThemeColorDialog extends StatefulWidget {
  const _ThemeColorDialog({
    required this.title,
    required this.initialColor,
  });

  final String title;
  final Color initialColor;

  @override
  State<_ThemeColorDialog> createState() => _ThemeColorDialogState();
}

class _ThemeColorDialogState extends State<_ThemeColorDialog> {
  late Color _selectedColor;
  late TextEditingController _hexController;
  late TextEditingController _redController;
  late TextEditingController _greenController;
  late TextEditingController _blueController;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _hexController = TextEditingController();
    _redController = TextEditingController();
    _greenController = TextEditingController();
    _blueController = TextEditingController();
    _syncControllers();
  }

  @override
  void dispose() {
    _hexController.dispose();
    _redController.dispose();
    _greenController.dispose();
    _blueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(AppRadii.medium),
                    border: Border.all(color: Colors.black12),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: AppThemePresets.colorChoices.map((color) {
                  final selected =
                      color.toARGB32() == _selectedColor.toARGB32();
                  return InkWell(
                    onTap: () => _updateColor(color),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black12,
                          width: selected ? 2 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.medium),
              TextField(
                controller: _hexController,
                decoration:
                    InputDecoration(labelText: l10n.customThemeColorHint),
                onChanged: (value) {
                  final parsed = AppThemePresets.parseHexColor(value);
                  if (parsed != null) {
                    _updateColor(parsed, syncText: false);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              _RgbEditorRow(
                label: 'R',
                controller: _redController,
                value: _selectedColor.r.toDouble(),
                onChanged: (value) => _updateColor(
                  Color.fromARGB(
                    255,
                    value.round(),
                    _selectedColor.g.round(),
                    _selectedColor.b.round(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              _RgbEditorRow(
                label: 'G',
                controller: _greenController,
                value: _selectedColor.g.toDouble(),
                onChanged: (value) => _updateColor(
                  Color.fromARGB(
                    255,
                    _selectedColor.r.round(),
                    value.round(),
                    _selectedColor.b.round(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              _RgbEditorRow(
                label: 'B',
                controller: _blueController,
                value: _selectedColor.b.toDouble(),
                onChanged: (value) => _updateColor(
                  Color.fromARGB(
                    255,
                    _selectedColor.r.round(),
                    _selectedColor.g.round(),
                    value.round(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedColor),
          child: Text(l10n.save),
        ),
      ],
    );
  }

  void _updateColor(Color color, {bool syncText = true}) {
    setState(() {
      _selectedColor = color;
      if (syncText) {
        _syncControllers();
      }
    });
  }

  void _syncControllers() {
    _hexController.text = AppThemePresets.toHex(_selectedColor);
    _redController.text = '${_selectedColor.r}';
    _greenController.text = '${_selectedColor.g}';
    _blueController.text = '${_selectedColor.b}';
  }
}

class _RgbEditorRow extends StatelessWidget {
  const _RgbEditorRow({
    required this.label,
    required this.controller,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 24, child: Text(label)),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            value: value.clamp(0, 255),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 64,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onSubmitted: (raw) {
              final parsed = int.tryParse(raw);
              if (parsed != null) {
                onChanged(parsed.clamp(0, 255).toDouble());
              }
            },
          ),
        ),
      ],
    );
  }
}

class _SettingSectionPage extends StatelessWidget {
  const _SettingSectionPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(title)), body: child);
  }
}
