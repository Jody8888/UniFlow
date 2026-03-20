import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'models/notice_model.dart';
import 'pages/home/notice_list_page.dart';
import 'pages/notice/notice_detail_page.dart';
import 'pages/setting/setting_page.dart';
import 'pages/user/user_info_page.dart';
import 'providers/notice_provider.dart';
import 'providers/user_provider.dart';
import 'services/api_service.dart';
import 'services/sort_service.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.create();
  runApp(UniFlowApp(bootstrap: bootstrap));
}

class AppBootstrap {
  AppBootstrap({
    required this.userProvider,
    required this.noticeProvider,
  });

  final UserProvider userProvider;
  final NoticeProvider noticeProvider;

  static Future<AppBootstrap> create() async {
    final storageService = StorageService();
    final apiService = ApiService();
    final sortService = SortService();

    final userProvider = UserProvider(storageService: storageService);
    await userProvider.initialize();

    final noticeProvider = NoticeProvider(
      apiService: apiService,
      storageService: storageService,
      sortService: sortService,
    );
    await noticeProvider.initialize(
      studentInfo: userProvider.studentInfo,
      preference: userProvider.preference,
    );

    userProvider.addListener(() {
      noticeProvider.applyPersonalization(
        studentInfo: userProvider.studentInfo,
        preference: userProvider.preference,
      );
    });

    return AppBootstrap(
      userProvider: userProvider,
      noticeProvider: noticeProvider,
    );
  }
}

class UniFlowApp extends StatelessWidget {
  const UniFlowApp({
    super.key,
    required this.bootstrap,
  });

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: bootstrap.userProvider),
        ChangeNotifierProvider<NoticeProvider>.value(value: bootstrap.noticeProvider),
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final seedColor = AppThemePresets.parseHexColor(
                userProvider.preference.customThemeColorHex,
              ) ??
              AppThemePresets.seedColors[userProvider.preference.themePreset] ??
              AppColors.brandPrimary;
          return MaterialApp(
            onGenerateTitle: (context) => context.l10n.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.buildTheme(
              brightness: Brightness.light,
              seedColor: seedColor,
            ),
            darkTheme: AppTheme.buildTheme(
              brightness: Brightness.dark,
              seedColor: seedColor,
            ),
            themeMode: _resolveThemeMode(userProvider.preference.themeMode),
            themeAnimationCurve: Curves.easeInOutCubic,
            themeAnimationDuration: const Duration(milliseconds: 450),
            locale: _resolveLocale(userProvider.preference.languageCode),
            supportedLocales: const <Locale>[
              Locale('zh', 'CN'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppRoutes.home,
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case AppRoutes.home:
                  return MaterialPageRoute<void>(
                    builder: (_) => const NoticeListPage(),
                  );
                case AppRoutes.userInfo:
                  return MaterialPageRoute<void>(
                    builder: (_) => const UserInfoPage(),
                  );
                case AppRoutes.setting:
                  return MaterialPageRoute<void>(
                    builder: (_) => const SettingPage(),
                  );
                case AppRoutes.noticeDetail:
                  final notice = settings.arguments;
                  return MaterialPageRoute<void>(
                    builder: (_) => NoticeDetailPage(
                      notice: notice is NoticeModel ? notice : null,
                    ),
                  );
                default:
                  return MaterialPageRoute<void>(
                    builder: (_) => const NoticeListPage(),
                  );
              }
            },
          );
        },
      ),
    );
  }

  Locale? _resolveLocale(String languageCode) {
    switch (languageCode) {
      case AppLanguageOptions.zhCn:
        return const Locale('zh', 'CN');
      case AppLanguageOptions.enUs:
        return const Locale('en', 'US');
      case AppLanguageOptions.system:
      default:
        return null;
    }
  }

  ThemeMode _resolveThemeMode(String themeMode) {
    switch (themeMode) {
      case AppThemeModes.light:
        return ThemeMode.light;
      case AppThemeModes.dark:
        return ThemeMode.dark;
      case AppThemeModes.system:
      default:
        return ThemeMode.system;
    }
  }
}
