import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/translations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme/app_theme.dart';
import '../app/theme/color_schemes.dart';
import '../features/settings/providers/settings_provider.dart';
import '../features/beranda/screens/beranda_screen.dart';
import '../features/berkas/screens/berkas_list_screen.dart';
import '../features/bundel/screens/bundel_screen.dart';
import '../features/settings/screens/settings_screen.dart';

class BerkasKuApp extends ConsumerWidget {
  const BerkasKuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = AppTheme.build(
      scheme: AppColorSchemes.fromString(settings.themePreset),
      isDark: settings.darkMode,
      fontSize: settings.fontSize,
    );

    return MaterialApp(
      title: 'BerkasKu',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
      ],
      theme: theme,
      darkTheme: AppTheme.build(
        scheme: AppColorSchemes.fromString(settings.themePreset),
        isDark: true,
        fontSize: settings.fontSize,
      ),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainScaffold(),
    );
  }
}

final _selectedTabProvider = StateProvider<int>((_) => 0);

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  static const _tabs = [
    BerandaScreen(),
    BerkasListScreen(),
    BundelScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(_selectedTabProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: selectedTab,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedTab,
        onTap: (index) =>
            ref.read(_selectedTabProvider.notifier).state = index,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Berkas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Bundel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
