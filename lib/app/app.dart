import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/translations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme/app_theme.dart';
import '../app/theme/color_schemes.dart';
import '../features/settings/providers/settings_provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/lock_screen.dart';
import '../features/beranda/screens/beranda_screen.dart';
import '../features/berkas/screens/berkas_list_screen.dart';
import '../features/berkas/providers/berkas_provider.dart';
import '../shared/models/berkas_model.dart';
import '../features/bundel/screens/bundel_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/widget/widget_service.dart';

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
      debugShowCheckedModeBanner: true,
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
      home: const _AuthGate(),
    );
  }
}

/// Shows LockScreen when a lock mode is active and user is not yet authenticated.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider);

    // No lock mode: show app directly
    if (settings.lockMode == 'none') return const MainScaffold();

    // Already authenticated
    if (auth.isAuthenticated) return const MainScaffold();

    // Biometric-only but device doesn't support it: skip
    if (settings.lockMode == 'biometric' && !auth.biometricAvailable) {
      return const MainScaffold();
    }

    // PIN mode but no PIN has been set yet: skip
    if (settings.lockMode == 'pin' && (settings.pinHash == null || settings.pinSalt == null)) {
      return const MainScaffold();
    }

    return const LockScreen();
  }
}

final _selectedTabProvider = StateProvider<int>((_) => 0);

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> with WidgetsBindingObserver {
  static const _tabs = [
    BerandaScreen(),
    BerkasListScreen(),
    BundelScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePendingWidgetAction();
      _updateWidget();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _updateWidget();
  }

  void _updateWidget() {
    WidgetService.updateRecentBerkas(ref.read(berkasProvider));
  }

  void _handlePendingWidgetAction() {
    final action = ref.read(pendingWidgetActionProvider);
    if (action == 'add_note' && mounted) {
      ref.read(pendingWidgetActionProvider.notifier).state = null;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BerkasListScreen(openCreateDialog: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(_selectedTabProvider);

    // Update home widget when berkas list changes
    ref.listen<List<BerkasModel>>(berkasProvider, (_, next) {
      WidgetService.updateRecentBerkas(next);
    });

    // Handle widget action when app is already running
    ref.listen<String?>(pendingWidgetActionProvider, (_, action) {
      if (action != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingWidgetAction());
      }
    });

    return Scaffold(
      body: IndexedStack(
        index: selectedTab,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedTab,
        onTap: (index) => ref.read(_selectedTabProvider.notifier).state = index,
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
