import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/api_source_config.dart';
import '../../providers/notice_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';

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
        builder: () => _buildUpdateSection(context, userProvider, noticeProvider),
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
        builder: () => _buildGeneralSection(context, userProvider, noticeProvider),
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
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Text(l10n.updateFrequency, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        Text(l10n.updateFrequencyDesc),
        const SizedBox(height: AppSpacing.medium),
        DropdownButtonFormField<int>(
          initialValue: preference.updateFrequencyMinutes,
          decoration: InputDecoration(labelText: l10n.autoUpdateFrequency),
          items: AppConstants.updateFrequencyOptions.map((value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(value == -1 ? l10n.noAutoUpdate : l10n.minutesLabel(value)),
            );
          }).toList(),
          onChanged: (value) async {
            if (value == null) {
              return;
            }
            await userProvider.updateUpdateFrequency(value);
            if (!mounted) {
              return;
            }
            _showMessage(messenger, value == -1 ? l10n.disabledAutoUpdate : l10n.updatedAutoUpdate);
          },
        ),
        const SizedBox(height: AppSpacing.large),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.currentDataSource, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.small),
                Text(preference.activeApiSource.name),
                const SizedBox(height: 4),
                Text(preference.activeApiSource.displayUrl, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.medium),
                FilledButton.icon(
                  onPressed: () async {
                    final success = await noticeProvider.refreshNotices(showLoading: true);
                    if (!mounted) {
                      return;
                    }
                    _showMessage(messenger, success ? l10n.manualRefreshDone : noticeProvider.errorMessage ?? l10n.manualRefreshFailed);
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

  Widget _buildApiSourceSection(BuildContext context, UserProvider userProvider) {
    final l10n = context.l10n;
    final preference = userProvider.preference;
    final messenger = ScaffoldMessenger.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Row(
          children: [
            Expanded(child: Text(l10n.dataSources, style: Theme.of(context).textTheme.titleLarge)),
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
                _showMessage(messenger, l10n.switchedApiSourceMessage(source.name));
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(source.name, style: Theme.of(context).textTheme.titleMedium)),
                        if (selected)
                          Chip(label: Text(l10n.currentSource), side: BorderSide.none),
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
                          onPressed: () => _createOrEditSource(context, userProvider, source: source),
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
                                  _showMessage(messenger, l10n.removedApiSourceMessage(source.name));
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
        Text(l10n.manualWeightSettings, style: Theme.of(context).textTheme.titleLarge),
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
                onPressed: () => _editWeight(context, userProvider, genre, value),
                child: Text(l10n.manualInput),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGeneralSection(BuildContext context, UserProvider userProvider, NoticeProvider noticeProvider) {
    final l10n = context.l10n;
    final preference = userProvider.preference;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Text(l10n.homeSortStandard, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        DropdownButtonFormField<String>(
          initialValue: preference.homeSortMode,
          decoration: InputDecoration(labelText: l10n.defaultSortMode),
          items: AppSortModes.values.map((mode) {
            return DropdownMenuItem<String>(value: mode, child: Text(l10n.sortModeLabel(mode)));
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
        Text(l10n.appearanceSettings, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        DropdownButtonFormField<String>(
          initialValue: preference.themeMode,
          decoration: InputDecoration(labelText: l10n.themeMode),
          items: AppThemeModes.values.map((value) {
            return DropdownMenuItem<String>(value: value, child: Text(l10n.themeModeLabel(value)));
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
            final seedColor = AppThemePresets.seedColors[value] ?? AppColors.brandPrimary;
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: seedColor, shape: BoxShape.circle)),
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
            title: Text(l10n.customThemeColor),
            subtitle: Text(preference.customThemeColorHex ?? l10n.themePresetLabel(preference.themePreset)),
            trailing: FilledButton.tonal(
              onPressed: () => _editCustomThemeColor(context, userProvider),
              child: Text(l10n.choose),
            ),
          ),
        ),
        if (preference.customThemeColorHex != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.small),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await userProvider.updateCustomThemeColor(null);
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
        Text(l10n.timelinePeriod, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        DropdownButtonFormField<String>(
          initialValue: preference.timelineRange,
          decoration: InputDecoration(labelText: l10n.timelineRange),
          items: AppTimelineRanges.values.map((value) {
            return DropdownMenuItem<String>(value: value, child: Text(l10n.timelineRangeLabel(value)));
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
        Text(l10n.settingsDisplayMode, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        DropdownButtonFormField<String>(
          initialValue: preference.settingsLayout,
          decoration: InputDecoration(labelText: l10n.settingsDisplayMode),
          items: AppSettingsLayouts.values.map((value) {
            return DropdownMenuItem<String>(value: value, child: Text(l10n.settingsLayoutLabel(value)));
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
        Text(l10n.languageSettings, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        DropdownButtonFormField<String>(
          initialValue: preference.languageCode,
          decoration: InputDecoration(labelText: l10n.appLanguage),
          items: AppLanguageOptions.values.map((value) {
            return DropdownMenuItem<String>(value: value, child: Text(l10n.languageLabel(value)));
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
                Text(l10n.dataManagement, style: Theme.of(context).textTheme.titleMedium),
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
                  style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: Text(l10n.resetAllSettings),
                          content: Text(l10n.resetAllSettingsConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(false),
                              child: Text(l10n.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(dialogContext).pop(true),
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
                Text(DeveloperInfo.teamName, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.small),
                Text(DeveloperInfo.description),
                const SizedBox(height: AppSpacing.medium),
                Text(l10n.version(DeveloperInfo.version)),
                const SizedBox(height: 4),
                Text(l10n.maintainer(DeveloperInfo.maintainer)),
                const SizedBox(height: 4),
                Text(l10n.contact(DeveloperInfo.contact)),
                const SizedBox(height: AppSpacing.large),
                Text(l10n.supportProject, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.small),
                Text(l10n.supportProjectDesc),
                const SizedBox(height: AppSpacing.medium),
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _openSupportLink(context, DeveloperInfo.buyMeACoffeeUrl),
                      icon: const Icon(Icons.local_cafe_outlined),
                      label: Text(l10n.buyMeCoffee),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openSupportLink(context, DeveloperInfo.afdianUrl),
                      icon: const Icon(Icons.favorite_border),
                      label: Text(l10n.afdian),
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
  Future<void> _createOrEditSource(BuildContext context, UserProvider userProvider, {ApiSourceConfig? source}) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController(text: source?.name ?? '');
    final baseUrlController = TextEditingController(text: source?.baseUrl ?? '');
    final pathController = TextEditingController(text: source?.noticePath ?? AppConstants.noticePath);
    var useMockData = source?.useMockData ?? false;

    final result = await showDialog<ApiSourceConfig>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogStateContext, setState) {
            return AlertDialog(
              title: Text(source == null ? l10n.addApiSource : l10n.editApiSource),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: InputDecoration(labelText: l10n.name)),
                    const SizedBox(height: AppSpacing.medium),
                    TextField(controller: baseUrlController, decoration: InputDecoration(labelText: l10n.baseUrl)),
                    const SizedBox(height: AppSpacing.medium),
                    TextField(controller: pathController, decoration: InputDecoration(labelText: l10n.noticePath)),
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
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.cancel)),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final baseUrl = baseUrlController.text.trim();
                    final noticePath = pathController.text.trim().isEmpty ? AppConstants.noticePath : pathController.text.trim();
                    final next = ApiSourceConfig(
                      id: source?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name.isEmpty ? l10n.unnamedSource : name,
                      baseUrl: baseUrl,
                      noticePath: noticePath,
                      useMockData: useMockData,
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

  Future<void> _editWeight(BuildContext context, UserProvider userProvider, String genre, double currentValue) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: currentValue.toStringAsFixed(2));
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.setGenreWeight(genre)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(labelText: l10n.weightHint),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.cancel)),
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

  Future<void> _editCustomThemeColor(BuildContext context, UserProvider userProvider) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: userProvider.preference.customThemeColorHex ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.customThemeColor),
          content: TextField(controller: controller, decoration: InputDecoration(labelText: l10n.customThemeColorHint)),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()), child: Text(l10n.save)),
          ],
        );
      },
    );

    if (result == null) {
      return;
    }

    await userProvider.updateCustomThemeColor(result.isEmpty ? null : result);
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
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
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
  const _SettingSectionData({required this.title, required this.icon, required this.builder});

  final String title;
  final IconData icon;
  final Widget Function() builder;
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
