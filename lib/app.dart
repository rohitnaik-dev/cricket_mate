import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/players/ui/players_screen.dart';
import 'features/sessions/ui/sessions_screen.dart';
import 'features/settings/state/settings_controller.dart';
import 'features/settings/ui/settings_screen.dart';

/// State provider for bottom navigation tab index (0: Sessions, 1: Players, 2: Settings).
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Main application widget configuring theme, localization, and navigation.
class CricketMateApp extends ConsumerWidget {
  const CricketMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainNavigationScreen(),
    );
  }
}

/// Root scaffold holding persistent 3-destination bottom navigation: Sessions, Players, Settings.
class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  static const List<Widget> _destinations = <Widget>[
    SessionsScreen(),
    PlayersScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final l10n = context.l10n;

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _destinations),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.sports_cricket_outlined),
            selectedIcon: const Icon(Icons.sports_cricket),
            label: l10n.sessionsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: l10n.playersTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settingsTab,
          ),
        ],
      ),
    );
  }
}
